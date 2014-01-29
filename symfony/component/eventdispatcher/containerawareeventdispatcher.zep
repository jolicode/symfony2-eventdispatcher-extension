/*
 * This file is part of the Symfony package.
 *
 * (c) Fabien Potencier <fabien@symfony.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace Symfony\Component\EventDispatcher;

/**
 * Lazily loads listeners and subscribers from the dependency injection
 * container
 *
 * @author Fabien Potencier <fabien@symfony.com>
 * @author Bernhard Schussek <bschussek@gmail.com>
 * @author Jordan Alliot <jordan.alliot@gmail.com>
 */
class ContainerAwareEventDispatcher extends Symfony\Component\EventDispatcher\EventDispatcher
{
    /**
     * The container from where services are loaded
     * @var ContainerInterface
     */
    private $container;

    /**
     * The service IDs of the event listeners and subscribers
     * @var array
     */
    private $listenerIds;

    /**
     * The services registered as listeners
     * @var array
     */
    private $listeners;

    /**
     * Constructor.
     *
     * @param ContainerInterface $container A ContainerInterface instance
     */
    public function __construct(<Symfony\Component\DependencyInjection\ContainerInterface> $container)
    {
        let $this->container = $container;
        let $this->listenerIds = [];
        let $this->listeners   = [];
    }

    /**
     * Adds a service as event listener
     *
     * @param string $eventName Event for which the listener is added
     * @param array  $callback  The service ID of the listener service & the method
     *                            name that has to be called
     * @param integer $priority The higher this value, the earlier an event listener
     *                            will be triggered in the chain.
     *                            Defaults to 0.
     *
     * @throws \InvalidArgumentException
     */
    public function addListenerService($eventName, $callback, $priority = 0)
    {
        var $listener_service;

        if (!is_array($callback) || 2 !== count($callback)) {
            throw new \InvalidArgumentException("Expected an array(\"service\", \"method\") argument");
        }

        let $listener_service = $this->listenerIds[$eventName];
        let $listener_service[] = [$callback[0], $callback[1], $priority];
        let $this->listenerIds[$eventName] = $listener_service;
    }

    public function removeListener($eventName, $listener)
    {
        var $key, $l, $i, $args, $priority, $method, $serviceId;

        $this->lazyLoad($eventName);

        if (isset($this->listeners[$eventName])) {

            for $key, $l in $this->listeners[$eventName] {
                for $i, $args in $this->listenerIds[$eventName] {

                    let $serviceId = $args[0];
                    let $method    = $args[1];
                    let $priority  = $args[2];

                    if ($key === sprintf("%s.%s", $serviceId, $method)) {
                        if ($listener === [$l, $method]) {
                            unset($this->listeners[$eventName][$key]);
                            if (empty($this->listeners[$eventName])) {
                                unset($this->listeners[$eventName]);
                            }
                            unset($this->listenerIds[$eventName][$i]);
                            if (empty($this->listenerIds[$eventName])) {
                                unset($this->listenerIds[$eventName]);
                            }
                        }
                    }
                }
            }
        }

        parent::removeListener($eventName, $listener);
    }

    /**
     * @see EventDispatcherInterface::hasListeners
     */
    public function hasListeners($eventName = null)
    {
        if (null === $eventName) {
            return count($this->listenerIds) > 0 || count($this->listeners) > 0;
        }

        if (isset($this->listenerIds[$eventName])) {
            return true;
        }

        return parent::hasListeners($eventName);
    }

    /**
     * @see EventDispatcherInterface::getListeners
     */
    public function getListeners($eventName = null)
    {
        var $serviceEventName;

        if (null === $eventName) {
            for $serviceEventName in array_keys($this->listenerIds) {
                $this->lazyLoad($serviceEventName);
            }
        } else {
            $this->lazyLoad($eventName);
        }

        return parent::getListeners($eventName);
    }

    /**
     * Adds a service as event subscriber
     *
     * @param string $serviceId The service ID of the subscriber service
     * @param string $class     The service's class name (which must implement EventSubscriberInterface)
     */
    public function addSubscriberService($serviceId, $class)
    {
        var $eventName, $params, $listener, $event, $priority;

        for $eventName, $params in {$class}::getSubscribedEvents() {
            if (is_string($params)) {
                let $event = $this->listenerIds[$eventName];
                let $event[] = [$serviceId, $params, 0];
                let $this->listenerIds[$eventName] = $event;
            } else {
                if (is_string($params[0])) {
                    let $event = $this->listenerIds[$eventName];
                    if (isset($params[1])) {
                        let $priority = $params[1];    
                    } else {
                        let $priority = 0;
                    }
                    
                    let $event[] = [$serviceId, $params[0], $priority];
                    let $this->listenerIds[$eventName] = $event;
                } else {
                    for $listener in $params {
                        let $event = $this->listenerIds[$eventName];
                        if (isset($listener[1])) {
                            let $priority = $listener[1];    
                        } else {
                            let $priority = 0;
                        }
                        
                        let $event[] = [$serviceId, $listener[0], $priority];
                        let $this->listenerIds[$eventName] = $event;
                    }
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     *
     * Lazily loads listeners for this event from the dependency injection
     * container.
     *
     * @throws \InvalidArgumentException if the service is not defined
     */
    public function dispatch($eventName, <Symfony\Component\EventDispatcher\Event> $event = null)
    {
        $this->lazyLoad($eventName);

        return parent::dispatch($eventName, $event);
    }

    public function getContainer()
    {
        return $this->container;
    }

    /**
     * Lazily loads listeners for this event from the dependency injection
     * container.
     *
     * @param string $eventName The name of the event to dispatch. The name of
     *                          the event is the name of the method that is
     *                          invoked on listeners.
     */
    protected function lazyLoad($eventName) -> void
    {
        var $serviceId, $method, $priority, $args, $listener, $key;

        if (isset($this->listenerIds[$eventName])) {
            for $args in $this->listenerIds[$eventName] {
                let $serviceId = $args[0];
                let $method    = $args[1];
                let $priority  = $args[2];
                let $listener  = $this->container->get($serviceId);
                let $key       = $serviceId.'.'.$method;

                if (!isset($this->listeners[$eventName][$key])) {
                    $this->addListener($eventName, [$listener, $method], $priority);
                } else {
                    if ($listener !== $this->listeners[$eventName][$key]) {
                        parent::removeListener($eventName, [$this->listeners[$eventName][$key], $method]);
                        $this->addListener($eventName, [$listener, $method], $priority);
                    }
                }

                let $this->listeners[$eventName][$key] = $listener;
            }
        }
    }
}