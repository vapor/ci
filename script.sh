input=$1
input=`echo $input | sed 's/ *$//g'`
inputEmpty=""
[ -z "$input" ] && inputEmpty=true || inputEmpty=false
echo $inputEmpty
echo "Input is empty: $inputEmpty"

if [ "$inputEmpty" == true ] ;
then
    json="{\"include\":[{ \"project\": \"unknown\", \"label\": \"unknown\" }]}"
    echo '==== Print json ===='
    echo $json
    echo ::set-output name=matrix::${json}
else
    echo '======================'
    echo 'Split input into array'
    echo '======================'
    echo $input
    SAVEIFS="$IFS"
    IFS=',' read -ra labels <<< $input
    IFS="$SAVEIFS"
    echo '======================'
    echo 'Create array with project board inputs'
    echo '======================'
    projectboards=("Beginner Issues" "Help Wanted Issues")
    echo '======================'
    echo 'Create json used for dynamic matrix definition'
    echo '======================'
    json="{\"include\":["
    for label in "${labels[@]}"
    do
        if [ "$label" == "good first issue" ] || [ "$label" == "help wanted" ];
        then
            for board in "${projectboards[@]}"
            do 
                json="$json{ \"project\": \"$board\", \"label\": \"$label\" },"
            done
        fi
    done
    json=${json%?}
    json="$json]}"
    if [ "$json" == "{\"include\":]}" ];
    then
        echo '======================'
        echo 'create invalid matrix if json is empty'
        echo '======================'
        json="{\"include\":[{ \"project\": \"Beginner Issues\", \"label\": \"good first issue\" }, { \"project\": \"Help Wanted Issues\", \"label\": \"help wanted\" }]}"
    fi 
    echo '==== Print json ===='
    echo $json
    echo ::set-output name=matrix::${json}
fi