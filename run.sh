#!/usr/bin/env bash
# run.sh
# 
# @author: Jack Kotheimer
# @date: 2/8/21
#
# The main functionality of the script is listed just below in the '_help' function, but if you have any questions about
# the functionality or implementation of this script, feel free to send me a message via email at jkotheimer9@gmail.com
#
# Enjoy!

###############################################################################
# -----------------------------------------------------------------------------
# PRETTY PRINTERS/ COMMAND HANDLER
# -----------------------------------------------------------------------------
###############################################################################

# Just some colorful output handlers to satisfy those who enjoy clean script responses
red=$'\033[0;31m'
yellow=$'\033[0;33m'
green=$'\033[0;32m'
blue=$'\033[0;34m'
nc=$'\033[0m'

# Print something in color
# $1: String to print
# $2: Color to print with
echoc() {
	printf "%s%s%s\n" "$2" "$1" "$nc"
}
# Print the description of a command before its execution
_print() {
	[ "$VERBOSE" -eq 1 ] && printf "%s...\n" "$@" || printf '[ .... ] %s' "$@"
}
_ok() {
	printf "\r[%s DONE %s]\n" "$green" "$nc"
}
_warn() {
	printf "\r[%s WARN %s] %s\n" "$yellow" "$nc" "$*"
}
# $1: Error message
# $2: (optional) '-' to print the error message inline with the [ FAIL ] flag
_err() {
	printf "\r[%s FAIL %s] " "$red" "$nc"
	[ -z "$2" ] && printf "\n"
	printf "%s\n" "$1"
	exit 1
}
# $1: Command to execute and handle
# $2: (optional) log file to save command output to
# $3: (optional) '-' to put an '&' after command to make it a background process
_handle() {
	# If a log file was specified, set it to the output variable
	LOG=logs/temp.log
	[ -n "$2" ] && LOG=logs/$2 
	STAT=0
	# If the daemon flag is set, send the command to the daemons
	if [ -n "$3" ]; then
		if [ "$VERBOSE" -eq 1 ]; then
			$1 | tee "$LOG" &
			STAT=${PIPESTATUS[0]}

			# If the daemon flag was a '/' under verbose mode, wait for the command to resolve
			# This is typically done if the command is the last command in a series, and you want to view it's output
			if [ "$3" = '/' ]; then
				wait
			else
				sleep 3
			fi
		else
			$1 &>"$LOG" &
			STAT=$?
			sleep 3
		fi
	else
		if [ "$VERBOSE" -eq 1 ]; then
			$1 | tee "$LOG"
			STAT=${PIPESTATUS[0]}
		else
			$1 &>"$LOG"
			STAT=$?
		fi
	fi

	# If the status was successful, print [ DONE ], else exit with the status code of the command
	if [ "$STAT" -eq 0 ]; then
		_ok
		[[ "$VERBOSE" -ne 1 && -n "$2" ]] && echoc "Log: $LOG" "$blue"
	else 
		if [ "$VERBOSE" -eq 1 ]; then
			_err "Status: $STAT" -
		else
			_err "$(tail -n 15 "$LOG")"
		fi
	fi
	return "$STAT"
}

###############################################################################
# -----------------------------------------------------------------------------
# HELP MENU
# -----------------------------------------------------------------------------
###############################################################################
_help() {
	# figlet is used to make bubble letters!
	FIG=0
	command -v figlet &>/dev/null && FIG=1 || echo Install figlet for bubble letters on your app name!
	
	echoc '-------------------------------------------------------------------' "$blue"
	printf '%s' "$blue"
	[ "$FIG" -eq 1 ] && figlet "$APP" || echo "$APP"
	echoc '-------------------------------------------------------------------' "$blue"
	echo 
	echo 'This script contains several functions to automate the software development process'
	echo 'Only one function may be executed at a time'
	echo 
	echo 'If you wish to add an operation to this script, contain it to a single function and add it to the'
	echo 'case statement at the bottom of this file. Document the function it serves in this help menu, and'
	echo 'create a pull request :)'
	echo 
	echoc '-----------------------------------------------' "$blue"
	echoc '|           HOW TO USE THIS SCRIPT            |' "$blue"
	echoc '-----------------------------------------------' "$blue"
	echoc './run.sh <primary> <secondary>' "$yellow"
	echo  '   <primary>   : (required) is any one of the below commands (a secondary command may be used as a primary)'
	echo  '   <secondary> : (optional) is any combination of secondary commands'
	echo 
	echoc '####################' "$blue"
	echoc '# ---------------- #' "$blue"
	printf "%s# %sPRIMARY COMMANDS %s#\n" "$blue" "$nc" "$blue"
	echoc '# ---------------- #' "$blue"
	echoc '####################' "$blue"
	echo 'Only one of these may be used at a time.'
	echo '----------------------------------------'
	echo '--boot         [-o]: Boot up the container without starting the server. (good for server debugging)'
	echo '--deploy       [-d]: Deploy the server'
	echo '    Dependencies from .config'
	echo '        - ENV: Environment to deploy to (dev, staging, production). See --env below'
	echo '        - TAG: Docker image tag to deploy with. See --tag below'
	echo 
	echoc '######################' "$blue"
	echoc '# ------------------ #' "$blue"
	printf "%s# %sSECONDARY COMMANDS %s#\n" "$blue" "$nc" "$blue"
	echoc '# ------------------ #' "$blue"
	echoc '######################' "$blue"
	echo 'Any number of these commands can be used in one call of this script in any order.'
	echo '---------------------------------------------------------------------------------'
	echoc 'Pre-primary -------------------------------------------------------' "$yellow"
	echo '--verbose     [-v]: Display verbose output on the primary function'
	echo '--kill        [-k]: Kill the docker container'
	echo '--pull        [-p]: Pull an image from Docker Hub'
	echo '--build       [-b]: Build a new Docker image'
	echo '--env <env>   [-e]: Switch environments to work in'
	echo '    <env> : dev, staging, or production'
	echoc "        Environment currently set to '$ENV'" "$green"
	echo '--tag <tag>   [-t]: Checkout a new tag name for your image'
	echo '    <tag> : Any string as a tag name'
	echoc "        Tag currently set to '$TAG'" "$green"
	echo '--host <host> [-H]: Set the host of the image for the current environment'
	echo "    <host>: The host to which you wish to push and pull the $ORG/${APP}_$ENV:$TAG image"
	NCOLOR="$green"
	[ -z "${DHOSTS[$ENV]}" ] && NCOLOR="$red"
	echoc "        Docker image host for $ENV currently set to '${DHOSTS[$ENV]}'" "$NCOLOR"
	echoc 'Remote specific commands' "$yellow"
	echo '--rebuild      [-R]: Rebuild ecs cluster (when switching between machines to use new ssh keypair)'
	echo "--aws-dns      [-D]: Fetch the most recent dns hostname for the $ENV server"
	NCOLOR="$green"
	[ -z "$AWS_DNS" ] && NCOLOR="$red"
	echoc "        $ENV dns hostname is currently set to '$AWS_DNS'" "$NCOLOR"
	echo '--aws-cred     [-A]: Re-enter AWS credentials'
	NCOLOR="$green"
	if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
		CREDSTAT=' not'
		NCOLOR="$red"
	fi
	echoc "        AWS credentials are currently$CREDSTAT set" "$NCOLOR"
	echo '--region <reg> [-G]: Set the AWS region to deploy to (default: us-east-1)'
	echo '    <reg> : Any AWS region'
	NCOLOR="$green"
	[ -z "$AWS_DEFAULT_REGION" ] && NCOLOR="$red"
	echoc "        AWS region is currently set to '$AWS_DEFAULT_REGION'" "$NCOLOR"
	echo '--keypair <kp> [-K]: Set the keypair to use when deploying remotely'
	echo '    <kp>  : An AWS registered ssh keypair name'
	NCOLOR="$green"
	[ -z "$KEYPAIR" ] && NCOLOR="$red"
	echoc "        AWS keypair is currently set to '$KEYPAIR'" "$NCOLOR"
	echo "--add-ssh-key  [-S]: Grant someone access to the $ENV server (must be an authorized user to do this)"
	echo 
	echoc 'Post-primary ------------------------------------------------------' "$yellow"
	echo '--help        [-h]: Show this help menu'
	echo '--push        [-u]: Push a recently built image to Docker Hub'
	echo '--clean       [-c]: Clean all dangling docker images'
	echo '--db-connect  [-C]: Connect to a database'
	echo '--dockershell [-l]: Enter the development docker container command line'
	echo '--logs        [-L]: Tail the server logs'
	echo 
}

###############################################################################
# -----------------------------------------------------------------------------
# DOCKER SHORTCUTS
# -----------------------------------------------------------------------------
###############################################################################

# Execute any bash command inside app container
dexec() {
	# TODO: Implement for remote server ssh
	if [ "$ENV" = dev ]; then
		docker exec -it "$APP" "$@" || _err
	else
		ssh -i ~/.ssh/$KEYPAIR ec2-user@$AWS_DNS $*
	fi
}
# Create and remove docker containers
create_docker_container() {
	kill_server -
	_print "Creating Docker container named $APP with image: $ORG/${APP}_$ENV:$TAG"
	_handle "docker run -d --rm \
			--env-file $(pwd)/deployment/$ENV/web.secret \
			--env-file $(pwd)/deployment/$ENV/web.env \
			--env-file $(pwd)/deployment/$ENV/db.secret \
			--env-file $(pwd)/deployment/$ENV/db.env \
			--env-file $(pwd)/deployment/$ENV/rabbitmq.secret \
			--env-file $(pwd)/deployment/$ENV/rabbitmq.env \
			--hostname com-$APP-app \
			--name $APP \
			-v $(pwd):/app \
			-p 80:80 \
			-it $ORG/${APP}_$ENV:$TAG $1" docker-run.log
}
kill_server() {
	if [[ "$ENV" = dev || $1 -eq 1 ]]; then
		_print "Killing local dev server"
		# not in a _handle because it doesn't matter if these fail
		docker kill "$APP" db rabbitmq &>/dev/null
		docker rm "$APP" db rabbitmq &>/dev/null
		_ok
	else
		read -r -n 1 -p "Are you sure you wish to stop the $APP $ENV task? [y/N]: " CHOICE
		echo
		[ "${CHOICE^^}" = Y ] || return 1
		_print "Stopping task"
		_handle "ecs_shortcut compose \
			--project-name $APP \
			service stop \
			--cluster-config $APP-$ENV \
			--ecs-profile $ORG-remote"
		_print "Removing service"
		_handle "ecs_shortcut compose \
			--project-name $APP \
			service rm \
			--cluster-config $APP-$ENV \
			--ecs-profile $ORG-remote"
		sleep 10

		read -r -n 1 -p "Would you like to kill the $ENV server? [y/N]: " CHOICE
		echo
		[ "${CHOICE^^}" = Y ] || return 1
		_print "killing $ENV server"
		_handle "ecs_shortcut down --force"
	fi
}
# Log in to an image host, dependant on current environment
docker_login() {
	if [ "$ENV" = dev ]; then
		docker login
	else
		aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${DHOSTS[$ENV]}"
	fi
}
# Push and pull containers to and from the image host
push_docker_image() {
	docker_login

	# Prepend the image host to the image tag so Docker knows where to send it
	docker tag "$ORG/${APP}_$ENV:$TAG" "${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"

	_print "Pushing image to ${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"
	_handle "docker push ${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"
}
pull_docker_image() {
	docker_login

	_print "Pulling image from ${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"
	_handle "docker pull ${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"
}
# Create and remove docker images
create_docker_image() {
	[ "$VERBOSE" -ne 1 ] && echoc 'Verbose output auto-enabled' "$yellow"
	VERBOSE=1
	remove_docker_image
	_print "Building Docker image: $ORG/${APP}_$ENV:$TAG (this may take a hot sec)"
	_handle "docker build --tag $ORG/${APP}_$ENV:$TAG --build-arg ENV=$ENV ." docker-init.log
	
	# If the environment is remote, push the image
	[ "$ENV" = dev ] || push_docker_image
}
remove_docker_image() {
	IMG=$(docker image ls -q "$ORG/${APP}_$ENV:$TAG")
	[ -z "$IMG" ] && return
	_print "Removing docker image: ${DHOSTS[$ENV]}/$ORG/${APP}_$ENV:$TAG"
	_handle "docker image rm -f $IMG"
}
clean_docker_images() {
	DANGLING=$(docker image ls -aqf dangling=true)
	[ -z "$DANGLING" ] && echo "Nothing to clean!" && return 0
	_print 'Cleaning dangling images'
	_handle "docker image rm -f $DANGLING"

	_print 'Pruning all unused volumes'
	_handle 'docker volume prune'
}

###############################################################################
# -----------------------------------------------------------------------------
# APPLICATION SPECIFIC SHORTCUTS
# -----------------------------------------------------------------------------
###############################################################################

ecs_shortcut() {
	[ "$ENV" = dev ] && _err "Operation not permitted in dev environment. Use --env to switch environments" -
	export COMPOSE_FILE="./deployment/$ENV/docker-compose.yml"
	ecs-cli "$@"
}
# Export all variables in a basic config file of key=value pairs
efile() {
	source "$1"
	export $(cut -d= -f1 "$1" | grep -v DHOSTS) &>/dev/null
}
enter_docker_shell() {
	if [ "$ENV" = dev ]; then
		docker exec -it "$APP" bash
	else
		check_remote_conf
		_warn 'Use "docker exec -it $(docker ps -qf name=web) bash" to enter docker container within ec2 instance' 
		ssh -i ~/.ssh/$KEYPAIR ec2-user@$AWS_DNS
	fi
}
get_logs() {
	if [ "$ENV" = dev ]; then
		tail -f logs/docker-compose.log
	else
		get_aws_task_id
		ecs-cli logs --task-id $AWS_TASK_ID --since 1 --follow
	fi
}
# When switching between machines or developers, use this command to allow ssh access with your keypair
rebuild_ecs_cluster() {
	# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-up.html
	_print "Generating $ENV ECS cluster..."
	_handle "ecs-cli up --cluster-config $APP-$ENV \
			--ecs-profile $ORG-remote \
			--keypair "$KEYPAIR" \
			--capability-iam \
			--size 1 \
			--instance-type t2.medium \
			--security-group sg-0f79330791670cf6e \
			--vpc vpc-eeb9ee94 \
			--subnets subnet-8fb64a81,subnet-6b070037,subnet-e80706c6,subnet-5cad6711,subnet-6bc6fd0c,subnet-6559175b \
			--force
			--verbose" ecs-up.log
}
add_ssh_key() {
	check_remote_conf

	read -r -s -p "Authority, enter your passcode: " PASSCODE
	echo
	read -r -p "New keypair name: " NEW_KEYPAIR
	read -r -s -p "New keypair passcode: " NEW_PASSCODE
	echo
	read -r -p "New public key: " NEW_PUBKEY
	
	ssh -i ~/.ssh/$KEYPAIR ec2-user@$AWS_DNS ssh_key_manager "$KEYPAIR" "$PASSCODE" "$NEW_KEYPAIR" "$NEW_PASSCODE" "$NEW_PUBKEY"
}


###############################################################################
# -----------------------------------------------------------------------------
# CONFIG GENERATION
# -----------------------------------------------------------------------------
###############################################################################

# Update a variable setting in any given config file
# $1: Variable name
# $2: Variable value
# $3: (optional) config file name - default=.config
update_conf() {
	[ -z "$2" ] && _err "Missing value for $1" -
	[ -z "$3" ] && conf='.config' || conf="$3"

	# If the key was supposed to be secret, replace the output value with asterisks 
	val="$2"
	[[ "$1" == *SECRET* ]] && val=$(for ((i=0; i<"${#val}"; i++)); do printf '*'; done)

	NAME="$(echo "$1" | tr '[]' '.*.*')"
	if grep "$NAME" "$conf" &>/dev/null; then
		cat "$conf" | sed "s|$NAME.*|$1=$2|" | cat > .temp
		mv .temp "$conf"
		echoc "$conf: $1 has been replaced with $val" "$blue"
	else
		echoc "$conf: $1 has been set to $val" "$blue"
		echo "$1=$2" >> "$conf"
	fi

	
	source "$conf"
	efile "$conf"
}
# Prompt for a config variable from user
# $1: Prompt text. (e.g. "AWS Access Key: ")
# $2: Variable name (e.g. AWS_ACCESS_KEY_ID)
# $3: Default value
prompt_conf() {
	
	if [[ "$1" == *secret* ]]; then
		read -r -s -p "$1" VALUE
	else
		read -r -p "$1" VALUE
	fi
	echo
	[ -z "$VALUE" ] && VALUE="$3"
	if [ -z "$VALUE" ]; then
		_warn 'This field cannot be left empty'
		prompt_conf "$1" "$2" "$3"
		return $?
	fi
	update_conf "$2" "$VALUE"
}
gen_app_conf() {
	read -r -p "Organization name: " ORG
	read -r -p "App name: " APP
	echo "ORG=$ORG
APP=$APP
ENV=dev
TAG=latest
declare -A DHOSTS
DHOSTS[dev]=dockerhub.io" > .config
	source .config
	efile .config
}

# Check for AWS credentials only when a remote deployment is underway
get_aws_cred() {
	prompt_conf 'AWS access key ID: ' AWS_ACCESS_KEY_ID
	prompt_conf 'AWS secret access key: ' AWS_SECRET_ACCESS_KEY
}
get_aws_dns() {
	_print "Retrieving AWS EC2 instance DNS hostname"
	AWS_DNS="$(aws ec2 describe-instances \
			--filter Name=tag:Name,Values="ECS Instance - amazon-ecs-cli-setup-$APP-$ENV" \
			| grep PublicDnsName \
			| head -1 \
			| sed 's/.*: "//g; s/".*//g')"
	[ $? -eq 0 ] && _ok || _err "$AWS_DNS"
	update_conf AWS_DNS "$AWS_DNS"
	update_conf ALLOWED_HOSTS "$AWS_DNS" "deployment/$ENV/web.env"
}
get_aws_task_id() {
	_print "Retrieving latest ECS task id"
	ATI="$(aws ecs list-tasks \
			--cluster "$APP-$ENV" \
			| grep "$AWS_DEFAULT_REGION.*$APP-$ENV" \
			| sed "s|.*$ENV/||g; s|\"||g")"
	[[ -z "$ATI" || $? -ne 0 ]] && _err 'Could not retrieve task id'
	_ok
	update_conf AWS_TASK_ID "$ATI"
}
# Verbose setter - default is off
VERBOSE=0
_verbose() {
	echoc 'Verbose output enabled' "$yellow"
	VERBOSE=1
}

###############################################################################
# -----------------------------------------------------------------------------
# REQUIREMENTS & CONFIG CHECK
# -----------------------------------------------------------------------------
###############################################################################

check_remote_conf() {
	[ -z "$AWS_DEFAULT_REGION" ] && prompt_conf 'AWS default region [default=us-east-1]: ' AWS_DEFAULT_REGION us-east-1
	[ -z "$KEYPAIR" ] && prompt_conf 'AWS keypair name: ' KEYPAIR
	[[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]] && get_aws_cred
	[ -z "${DHOSTS[${ENV}]}" ] && prompt_conf "Image host for $ORG/${APP}_$ENV:$TAG [default=dockerhub.io]: " "DHOSTS[$ENV]" dockerhub.io

	# This ensures that you aren't prompted for your ssh key passphrase every time we do something to the remote server
	grep 'AddKeysToAgent yes' ~/.ssh/config &>/dev/null || echo 'AddKeysToAgent yes' >> ~/.ssh/config

	# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-configure.html
	_print "Setting ecs config for $ENV"
	_handle "ecs-cli configure \
			--cluster $APP-$ENV \
			--default-launch-type EC2 \
			--config-name $APP-$ENV \
			--region $AWS_DEFAULT_REGION"
	
	# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-configure-profile.html
	_print "Applying ecs profile"
	_handle "ecs-cli configure profile --profile-name $ORG-remote"

	[ -z "$AWS_DNS" ] && get_aws_dns
	
	req_check ecs-cli aws
}

# Check for missing required software
req_check() {
	ERR=()
	for cmd in "$@"; do
		command -v "$cmd" &>/dev/null || ERR+=("$cmd")
	done
	[ ${#ERR[@]} -gt 0 ] && _err "You must install the following package(s) in order to deploy this project: ${ERR[*]}" -
}

if [ $EUID -eq 0 ]; then
	_warn 'Hold your horses! You are running this script as root, meaning other users will not be able to access many of the generated server resources.'
	read -r -n 1 -p 'Are you sure you wish to continue? [y/N] ' CHOICE
	echo
	[[ ${CHOICE^^} != 'Y' ]] && exit 1
fi
mkdir -p logs/
req_check docker docker-compose

# Check for valid .config, then export all it's variables
if ! grep APP .config &>/dev/null; then
	_warn 'Invalid .config'
	read -r -n 1 -p 'Regenerate? [Y/n]: ' CHOICE
	echo
	[[ ${CHOICE^^} != 'Y' ]] && exit 1
	gen_app_conf
fi
source .config
efile .config

###############################################################################
# -----------------------------------------------------------------------------
# DEPLOYMENT MECHANISM
# -----------------------------------------------------------------------------
###############################################################################

_deploy() {
	
	export COMPOSE_FILE="./deployment/$ENV/docker-compose.yml"
	export DHOST="${DHOSTS[$ENV]}"

	# For dev, just run the compose app and get outta here
	if [ "$ENV" = dev ]; then
		_print "Deploying dev server"
		_handle "docker-compose up" docker-compose.log /
	else
		check_remote_conf

		echoc "Copying $(pwd) to $AWS_DNS:/app" "$yellow"
		scp -r -i ~/.ssh/$KEYPAIR $(pwd)/* ec2-user@$AWS_DNS:/app

		# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-service-up.html
		_print "Composing $APP to $ENV with ECS"
		_handle "ecs-cli compose \
				--project-name $APP \
				service up \
				--cluster-config $APP-$ENV \
				--ecs-profile $ORG-remote \
				--force-deployment" ecs-compose.log
				#--create-log-groups <- Add this back in if you can't access the logs
	fi
}

###############################################################################
# -----------------------------------------------------------------------------
# FLAG PARSING & FUNCTION EXECUTION
# -----------------------------------------------------------------------------
###############################################################################

# This function "converts" an argument tag (like --verbose or -v) into a function name
# @param: $1 an argument tag
# @returns: 0, 1, 2, 3, or 4
#   0: pre-primary (no follow-up value)
#   1: pre-primary (with follow-up value. e.g.: --tag <tagname>. (<tagname> is the follow-up value))
#   2: primary
#   3: primary (with multiple follow up values : no other sub-commands may be used with this)
#   4: post-primary
parse_cmd() {
	case "$1" in
		####################
		# PRIMARY COMMANDS #
		####################
		--deploy | -d)
			echo _deploy
			return 2;;
		--boot | -o)
			echo create_docker_container bash
			return 2;;
		--ecs)
			echo ecs_shortcut
			return 3;;

		######################
		# SECONDARY COMMANDS #
		######################
		# Pre-primary
		# -----------
		--verbose | -v)
			echo _verbose;;
		# Docker shortcuts
		--kill | -k)
			echo kill_server
			return 0;;
		--pull | -p)
			echo pull_docker_image
			return 0;;
		--build | -b)
			echo create_docker_image
			return 0;;
		# Remote specific
		--rebuild | -R)
			[ "$ENV" = dev ] && _err "Operation not allowed in current environment: $ENV"
			echo rebuild_ecs_cluster
			return 0;;
		--aws-task-id | -I)
			echo get_aws_task_id
			return 0;;
		--aws-dns | -D)
			echo get_aws_dns
			return 0;;
		--aws-cred | -A)
			echo get_aws_cred
			return 0;;
		--add-ssh-key | -S)
			echo add_ssh_key
			return 0;;
		# State changers
		--tag | -t)
			echo update_conf TAG
			return 1;;
		--env | -e)
			echo update_conf ENV
			return 1;;
		--host | -H)
			echo update_conf DHOSTS["$ENV"]
			return 1;;
		--keypair | -K)
			echo update_conf KEYPAIR
			return 1;;
		--aws-region | -G)
			echo update_conf AWS_DEFAULT_REGION
			return 1;;

		# Post-primary
		# ------------
		--help | -h)
			echo _help
			return 4;;
		--dockershell | -l)
			echo enter_docker_shell
			return 4;;
		--db-connect | -C)
			echo db_connect
			return 4;;
		--push | -u)
			echo push_docker_image
			[ "$ENV" = dev ] && return 4 || return 0;;
		--clean | -c)
			echo clean_docker_images
			return 4;;
		--logs | -L)
			echo get_logs
			return 4;;
		
		#########
		# Error #
		#########
		*)
			return 255;;
	esac
}

# The pre- and post-primary commands are placed in separate arrays to be executed at their respective times
PRE=()
PRIMARY=''
POST=()
set_tack=''
var_set=''
for cmd in "$@"; do

	# If the last cmd was a variable setter (e.g. --tag or --env), append the current cmd (which would be the value) to that function call, then continue
	if [ -n "$var_set" ]; then
		
		# Spelling autocorrect based on the first letter of environment
		if [ "${var_set//* }" = ENV ]; then
			case "${cmd:0:1}" in
				d)
					cmd=dev;;
				s)
					cmd=staging;;
				p)
					cmd=production;;
				*)
					_err "Invalid environment: $cmd" -
			esac
		fi

		# Add the function call to the pre-primary commands, reset and continue parsing
		PRE+=( "$var_set $cmd" )
		unset var_set set_tack
		continue
	fi
	
	# Verbose mode should be the very first thing to be executed, so if it was set, enable verbose now
	[[ "$cmd" = --verbose || "$cmd" = -v ]] && _verbose && continue

	next=$(parse_cmd "$cmd")
	case "$?" in
		0)
			PRE+=( "$next" );;
		1)
			set_tack="$cmd"
			var_set="$next";;
		2)
			[ -n "$PRIMARY" ] && _err "Multiple primary command issued: $cmd" -
			PRIMARY="$next";;
		3)
			shift
			$next "$@"
			exit $?;;
		4)
			POST+=( "$next" );;
	esac
done


#grep -e ${var_set/* /} .config
if [ -n "$var_set" ]; then
	VAL="echo $(grep "$( echo ${var_set/* /} | sed 's|\[|.*|g; s|\]||g' )" .config | sed 's/.*=//g' )"
	[ "$VAL" = "echo " ] && VAL="_warn ${var_set/* /} is not set"
	PRE+=( "$VAL" )
fi

[[ -z "$PRE" && -z "$PRIMARY" && -z "$POST" ]] && _help && exit 1

# Execute the commands in proper order
for cmd in "${PRE[@]}"; do $cmd; done
$PRIMARY
for cmd in "${POST[@]}"; do $cmd; done
