#!/bin/bash

function cleanup () {
	rm -rf curls.sh
}

trap cleanup EXIT ERR INT TERM

gpg --output curls.sh -d curls.sh.asc
chmod +x curls.sh
./curls.sh $@


