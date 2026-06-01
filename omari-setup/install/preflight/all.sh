source $OMARI_INSTALL/preflight/guard.sh
source $OMARI_INSTALL/preflight/begin.sh
source $OMARI_INSTALL/preflight/identification.sh
run_logged $OMARI_INSTALL/preflight/migrations.sh
run_logged $OMARI_INSTALL/preflight/first-run-mode.sh
run_logged $OMARI_INSTALL/preflight/network.sh
