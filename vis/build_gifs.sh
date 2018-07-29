# a hacky script to produce some gif animations

#MODE=$1
#RUN_ID=$2

FORMAT="png"
SRC="~/data/mcn/contrib-matconvnet/mcnOptim/figs/gif_frames"
DEST="~/data/mcn/contrib-matconvnet/mcnOptim/figs/gifs"

#case "$MODE" in

#0) GIF_TYPE="loss"
    #;;
#1) GIF_TYPE="sol"
    #;;
#esac

NUM_RUNS=10

for RUN_ID in $(seq 3 $NUM_RUNS);

	do echo $RUN_ID ;
	declare -a GIF_TYPES=("loss" "sol")

	for GIF_TYPE in "${GIF_TYPES[@]}"
	do
		echo "($RUN_ID)/$NUM_RUNS converting $GIF_TYPE trajectories to gifs"
		TRAJECTORY_TEMPLATE="$GIF_TYPE-trajectory-${RUN_ID}-*.$FORMAT"
		src_files=( $(find ${SRC} -name $TRAJECTORY_TEMPLATE -type f | sort) )
		convert -loop 0 -delay 10 ${src_files[@]} "$DEST/$GIF_TYPE-trajectory-$RUN_ID.gif"
	done

done
