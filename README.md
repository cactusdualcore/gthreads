# gthreads

A tiny implementation of cooperative userspace threading as a
zig library.

This is an experiment and not meant for production usage! Therefore
I won't provide versioning or a changelog. If you want to use green threads
in your app, try [GNU Pth](https://www.gnu.org/software/pth/) or write it
in a language with built-in support like [Go](https://go.dev/tour/concurrency/1)
or [Java 19](https://openjdk.org/jeps/444).

But if you, like me, are interested in green threading, this might
be what you're looking for. It was initially inspired by
[Green Threads Explained](https://c9x.me/articles/gthreads/intro.html)
and then modified for my purpose.

The code in this repository will mostly not be portable, because of the
handwritten assembly for saving and loading register values.
