Bfs
===

An Elixir library for breadth-first search problem solving. See
[BFS](lib/bfs.ex) for documentation.


    iex -S mix
    pid = KnightsTour.start(5, 5)
    (wait 80 seconds or so)
    got it
    start
    start at 1,1
    move to 3,2
    ...

Unfortunately, Elixir is pretty slow..  It takes 80 seconds to find a
solution of the knight's tour on a 5x5 board using all 8 cores.  In
contrast, a single-threaded C program [knight.c](knight.c) can find
all solutions in about 2 seconds.

    gcc -Wall -O2 -o knight knight.c
    knight 5
  
2015-10-29 Noel Burton-Krahn <noel@burton-krahn.com>

