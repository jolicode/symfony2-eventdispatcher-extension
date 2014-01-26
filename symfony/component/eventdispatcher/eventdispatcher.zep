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
class EventDispatcher implements Symfony\Component\EventDispatcherInterface
{
    private $listeners = [];
    private $sorted = [];

    /**
     * @see EventDispatcherInterface::dispatch
     *
     * @api
     */
    public function dispatch(string $eventName, <Event> $event = null) -> <Event>
    {
        if (null === $event) {
            let $event = new Event();
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
    public function hasListeners($eventName = null)
    {
        return (Boolean) count($this->getListeners($eventName));
    }

    /**
     * @see EventDispatcherInterface::addListener
     *
     * @api
     */
    public function addListener($eventName, $listener, $priority = 0)
    {
        array_push($this->listeners[$eventName][$priority], $listener);
        unset($this->sorted[$eventName]);
    }

    /**
     * @see EventDispatcherInterface::removeListener
     */
    public function removeListener($eventName, $listener)
    {
        var $key;

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
    public function addSubscriber(<EventSubscriberInterface> $subscriber)
    {
        for $eventName, $params in $subscriber->getSubscribedEvents() {
            if (is_string($params)) {
                $this->addListener($eventName, [$subscriber, $params]);
            } else {
                if (is_string($params[0])) {
                    $this->addListener($eventName, [$subscriber, $params[0]], isset($params[1]) ? $params[1] : 0);
                } else {
                    for $listener in $params {
                        $this->addListener($eventName, [$subscriber, $listener[0]], isset($listener[1]) ? $listener[1] : 0);
                    }
                }
            }
        }
    }

    /**
     * @see EventDispatcherInterface::removeSubscriber
     */
    public function removeSubscriber(<EventSubscriberInterface> $subscriber)
    {
        for $eventName, $params in $subscriber->getSubscribedEvents() {
            if (is_array($params) && is_array($params[0])) {
                for $listener in $params {
                    $this->removeListener($eventName, [$subscriber, $listener[0]]);
                }
            } else {
                $this->removeListener($eventName, [$subscriber, is_string($params) ? $params : $params[0]]);
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
    protected function doDispatch($listeners, $eventName, <Event> $event)
    {
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
        let $this->sorted[$eventName] = [];

        if (isset($this->listeners[$eventName])) {
            krsort($this->listeners[$eventName]);
            let $this->sorted[$eventName] = call_user_func_array('array_merge', $this->listeners[$eventName]);
        }
    }
}