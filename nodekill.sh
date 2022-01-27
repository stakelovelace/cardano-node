kill -s INT $(ps -ef | grep [c]ardano-node | awk '{print $2}')
