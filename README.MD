
org2slides
===

Turn .org orgmode files into html slides (via Reveal.js)


Dependencies
===========

Ruby.


Install
=======

`gem install org2slides`


Usage
=====

`org2slides ORG_FILE_PATH`


Testing
=====

To hack on this and test the code, clone it, then run the following
whenever you need to do a smoketest:

	ruby -Ilib bin/org2slides test.org && open test_generated_slides/index.html


License
=======

org2slides is free software licensed under the
[GNU Affero General Public License (AGPL)](http://www.gnu.org/licenses/agpl-3.0.html).
