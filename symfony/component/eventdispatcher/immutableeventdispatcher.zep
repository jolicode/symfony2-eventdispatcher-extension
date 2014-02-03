namespace Symfony\Component\EventDispatcher;

/**
 * A read-only proxy for an event dispatcher.
 *
 * @author Bernhard Schussek <bschussek@gmail.com>
 * @author Damien Alexandre <dalexandre@jolicode.com>
 */
class ImmutableEventDispatcher implements Symfony\Component\EventDispatcher\EventDispatcherInterface
{
    /**
     * The proxied dispatcher.
     * @var EventDispatcherInterface
     */
    private $dispatcher;

    /**
     * Creates an unmodifiable proxy for an event dispatcher.
     *
     * @param EventDispatcherInterface $dispatcher The proxied event dispatcher.
     */
    public function __construct(<EventDispatcherInterface> $dispatcher)
    {
        let $this->dispatcher = $dispatcher;
    }

    /**
     * {@inheritdoc}
     */
    public function dispatch($eventName, <Event> $event = null)
    {
        return $this->dispatcher->dispatch($eventName, $event);
    }

    /**
     * {@inheritdoc}
     */
    public function addListener($eventName, $listener, $priority = 0)
    {
        throw new \BadMethodCallException("Unmodifiable event dispatchers must not be modified.");
    }

    /**
     * {@inheritdoc}
     */
    public function addSubscriber(<EventSubscriberInterface> $subscriber)
    {
        throw new \BadMethodCallException("Unmodifiable event dispatchers must not be modified.");
    }

    /**
     * {@inheritdoc}
     */
    public function removeListener($eventName, $listener)
    {
        throw new \BadMethodCallException("Unmodifiable event dispatchers must not be modified.");
    }

    /**
     * {@inheritdoc}
     */
    public function removeSubscriber(<EventSubscriberInterface> $subscriber)
    {
        throw new \BadMethodCallException("Unmodifiable event dispatchers must not be modified.");
    }

    /**
     * {@inheritdoc}
     */
    public function getListeners($eventName = null)
    {
        return $this->dispatcher->getListeners($eventName);
    }

    /**
     * {@inheritdoc}
     */
    public function hasListeners($eventName = null)
    {
        return $this->dispatcher->hasListeners($eventName);
    }
}