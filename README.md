Symfony2 Event Dispatcher as PHP extension
==========================================

This is an experimental WIP of the Symfony2 [EventDispatcher](https://github.com/symfony/EventDispatcher/tree/2.4) (version 2.4) rewritten in [Zephir](http://zephir-lang.com/index.html).

Some stuffs does not work at the moment:

- https://github.com/phalcon/zephir/issues/131
- https://github.com/phalcon/zephir/issues/124
- SegFault... :cry:

This is a work in progress, tests are red even if the extension compile.
The goal is to be able to run the phpunit tests from the original component against the extension.

Install
-------

You will need [Zephir](https://github.com/phalcon/zephir) to build and install this extension.

Running the test
----------------

    composer install
    zephir build && php -dextension=symfony.so /usr/local/bin/phpunit

License
-------

Everything is under the same [MIT license](https://github.com/symfony/EventDispatcher/blob/2.4/LICENSE) as Symfony2.