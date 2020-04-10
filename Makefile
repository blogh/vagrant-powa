export VAGRANT_BOX_UPDATE_CHECK_DISABLE=1
export VAGRANT_CHECKPOINT_DISABLE=1

.PHONY: all powa pgsql clean validate

all: powa pgsql

powa:
	vagrant up --provision-with powa-postgresql-setup,powa-powa-client-setup,powa-web-setup

pgsql:
	vagrant up --provision-with pg-postgresql-setup,pg-powa-client-setup

clean:
	vagrant destroy -f

validate:
	@vagrant validate
	@if which shellcheck >/dev/null                                          ;\
	then shellcheck provision/*                                              ;\
	else echo "WARNING: shellcheck is not in PATH, not checking bash syntax" ;\
	fi

