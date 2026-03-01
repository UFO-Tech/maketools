c:
	composer $(CMD)

install: CMD=install
install: c

update: CMD=update
update: c

require: CMD=require
require: c

i: install
u: update
r: require