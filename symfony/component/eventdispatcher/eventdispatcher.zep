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
 * The EventDispatcherInterface is the central point of Symfony's event listener system.
 *
 * Listeners are registered on the manager and events are dispatched through the
 * manager.
 *
 * @author  Guilherme Blanco <guilhermeblanco@hotmail.com>
 * @author  Jonathan Wage <jonwage@gmail.com>
 * @author  Roman Borschel <roman@code-factory.org>
 * @author  Bernhard Schussek <bschussek@gmail.com>
 * @author  Fabien Potencier <fabien@symfony.com>
 * @author  Jordi Boggiano <j.boggiano@seld.be>
 * @author  Jordan Alliot <jordan.alliot@gmail.com>
 *
 * @api
 */
class EventDispatcher implements Symfony\Component\EventDispatcher\EventDispatcherInterface
{
    private $listeners;
    private $sorted;

    public function __construct()
    {
        let $this->listeners = [];
        let $this->sorted = [];
    }

    /**
     * @see EventDispatcherInterface::dispatch
     *
     * @api
     */
    public function dispatch(string $eventName, <Symfony\Component\EventDispatcher\Event> $event = null) -> <Symfony\Component\EventDispatcher\Event>
    {
        if (null === $event) {
            let $event = new Symfony\Component\EventDispatcher\Event();
        }

        $event->setDispatcher($this);
        $event->setName($eventName);

        if (!isset($this->listeners[$eventName])) {
            return $event;
        }

        $this->doDispatch($this->getListeners($eventName), $eventName, $event);

        return $event;
    }

    /**
     * @see EventDispatcherInterface::getListeners
     */
    public function getListeners($eventName = null)
    {
        if (null !== $eventName) {
            if (!isset($this->sorted[$eventName])) {
                $this->sortListeners($eventName);
            }

            return $this->sorted[$eventName];
        }

        for eventName in $this->listeners {
            if (!isset($this->sorted[$eventName])) {
                $this->sortListeners($eventName);
            }
        }

        return $this->sorted;
    }

    /**
     * @see EventDispatcherInterface::hasListeners
     */
    public function hasListeners($eventName = null) -> boolean
    {
        return count($this->getListeners($eventName)) > 0;
    }

    /**
     * @see EventDispatcherInterface::addListener
     *
     * @api
     */
    public function addListener($eventName, $listener, $priority = 0)
    {
        // Does this works... ?
        if (!is_array($this->listeners[$eventName])) {
            let $this->listeners[$eventName] = [];
        }
        let $this->listeners[$eventName][$priority] = $listener;

        //array_push($this->listeners[$eventName][$priority], $listener);
        unset($this->sorted[$eventName]);
    }

    /**
     * @see EventDispatcherInterface::removeListener
     */
    public function removeListener($eventName, $listener)
    {
        var $key, $priority, $listeners;

        if (!isset($this->listeners[$eventName])) {
            return;
        }

        //foreach ($this->listeners[$eventName] as $priority => $listeners) {
        for $priority, $listeners in $this->listeners[$eventName] {
            let $key = array_search($listener, $listeners, true);

            if (false !== $key) {
                unset $this->listeners[$eventName][$priority][$key];
                unset $this->sorted[$eventName];
            }
        }
    }

    /**
     * @see EventDispatcherInterface::addSubscriber
     *
     * @api
     */
    public function addSubscriber(<Symfony\Component\EventDispatcher\EventSubscriberInterface> $subscriber)
    {
        var $eventName, $params, $listener, $priority;

        for $eventName, $params in $subscriber->getSubscribedEvents() {
            if (is_string($params)) {
                $this->addListener($eventName, [$subscriber, $params]);
            } else {
                if (is_string($params[0])) {
                    if (isset($params[1])) {
                        let $priority = $params[1];    
                    } else {
                        let $priority = 0;
                    }

                    $this->addListener($eventName, [$subscriber, $params[0]], $priority);
                } else {
                    for $listener in $params {
                        if (isset($listener[1])) {
                            let $priority = $listener[1];    
                        } else {
                            let $priority = 0;
                        }

                        $this->addListener($eventName, [$subscriber, $listener[0]], $priority);
                    }
                }
            }
        }
    }

    /**
     * @see EventDispatcherInterface::removeSubscriber
     */
    public function removeSubscriber(<Symfony\Component\EventDispatcher\EventSubscriberInterface> $subscriber)
    {
        var $eventName, $params, $listener, $name;

        for $eventName, $params in $subscriber->getSubscribedEvents() {
            if (is_array($params) && is_array($params[0])) {
                for $listener in $params {
                    $this->removeListener($eventName, [$subscriber, $listener[0]]);
                }
            } else {
                if (is_string($params)) {
                    let $name = $params;    
                } else {
                    let $name = $params[0];
                }

                $this->removeListener($eventName, [$subscriber, $name]);
            }
        }
    }

    /**
     * Triggers the listeners of an event.
     *
     * This method can be overridden to add functionality that is executed
     * for each listener.
     *
     * @param callable[] $listeners The event listeners.
     * @param string     $eventName The name of the event to dispatch.
     * @param Event      $event     The event object to pass to the event handlers/listeners.
     */
    protected function doDispatch($listeners, $eventName, <Symfony\Component\EventDispatcher\Event> $event)
    {
        var $listener;

        for $listener in $listeners {
            call_user_func($listener, $event, $eventName, $this);
            if ($event->isPropagationStopped()) {
                break;
            }
        }
    }

    /**
     * Sorts the internal list of listeners for the given event by priority.
     *
     * @param string $eventName The name of the event.
     */
    private function sortListeners($eventName)
    {
        var $function_name = 'array_merge';

        let $this->sorted[$eventName] = [];

        if (isset($this->listeners[$eventName])) {
            krsort($this->listeners[$eventName]);
            let $this->sorted[$eventName] = call_user_func_array($function_name, $this->listeners[$eventName]);
        }
    }
}