# install-scripts

A set of basic shell scripts for generating installer packages in various formats.
The idea here is to take the output of a maven build of a Java project and bundle
it up into an installer package that can be run on a linux system.

Roadmap:

- tarball format (done)
- RPM format (todo)
- DEB format (todo)
- Widnows installer (ain't gonna happen)
- MacOS installer (nah)

I actually find the tarball format good enough for my purposes, so even RPM and DEB support may not need to happen.

History:

- ported from old sc-util code and updated somewhat
- most of this is legacy


