#-------------------------------------------------------------------------------------------------------------------------------------------------------
function calcular_tfidf() {

    nfilas=$1 #Recuperar los 4 parámetros
    ncolumnas=$2
    matriz2=$3
    nombreFicheroFrecuencia=$4

    #    echo "Número de filas en la función: $nfilas"
    #    echo "Número de columnas en la función: $ncolumnas"
    #    echo "Nombre del fichero de frecuencias: $nombreFicheroFrecuencia"

    #    echo "Visualizar la matriz cargada"
    #    for ((i=1; i<=nfilas; i++)); do
    #        for ((j=1; j<=ncolumnas; j++)); do
    #            printf "%3s|" "${matriz2[$i,$j]}"
    #        done
    #        echo
    #    done

    #-calcular el TF de cada término en cada correo
    ncolumnas=$((ncolumnas - 1))
    for ((i = 1; i <= nfilas; i++)); do
        total_palabras="${matriz2[$i, $((ncolumnas + 1))]}"
        #echo "Total palabras correo $i: $total_palabras"
        for ((j = 3; j <= ncolumnas; j++)); do
            tf=$(echo "scale=2; ${matriz2[$i, $j]} / $total_palabras" | bc)
            matriz2[$i, $j]=$tf
        done
    done

    echo "Matriz: TF"
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 1; j <= ncolumnas; j++)); do
            printf "%3s|" "${matriz2[$i, $j]}"
        done
        echo
    done

    echo -e "Calcular el IDF de cada término. Para ello, calcular para cada columna, todas las celdas que no sean 0.\n
IDF: log10 (nº total de correos/nº correos con el término x) "

    for ((j = 3; j <= ncolumnas; j++)); do #Inicializar a 0 lal fila nueva
        matriz2[$((nfilas + 1)), $j]=0
    done

    n=1
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 3; j <= ncolumnas; j++)); do
            valor_matriz="${matriz2[$i, $j]}"
            if [ "$(echo "$valor_matriz != 0.0" | bc -l)" -eq 1 ]; then #Ver las celdas que son diferente de 0
                #echo "valor matriz = $valor_matriz"
                matriz2[$((nfilas + 1)), $j]=$((${matriz2[$((nfilas + 1)), $j]} + 1)) #sumo 1 a la fila que creo para el IDF
                #echo "Entra $n veces"
                n=$((n + 1))

            fi

        done
    done

    #    echo "Contador IDF ya calculado"
    #    for ((i=nfilas+1;i<=nfilas+1;i++)) do
    #        for ((j=1;j<=ncolumnas;j++)) do
    #            printf "%3s|" "${matriz2[$i,$j]}"
    #        done
    #    echo
    #    done
    #    echo "---------------------------------------------------------------------------"
    #    echo "prueba"

    for ((j = 3; j <= ncolumnas; j++)); do
        valor_matriz=${matriz2[$((nfilas + 1)), $j]}
        #Si es distinto de 0 y no está vacía, calculo el IDF
        if [ -n "$valor_matriz" ] && [ "$valor_matriz" -ne 0 ]; then
            resultado=$(echo "scale=2; l($nfilas / $valor_matriz) / l(10)" | bc -l)
            #echo "Resultado del logaritmo: $resultado"
            #Si no, le asigno un 0 directamente, porque no se puede dividir por 0.
        else
            resultado=0
        fi
        matriz2[$((nfilas + 1)), $j]=$resultado
    done

    echo "Visualizar la matriz con la fila final: IDF ya calculado"
    for ((i = 1; i <= nfilas + 1; i++)); do
        for ((j = 1; j <= ncolumnas; j++)); do
            printf "%3s|" "${matriz2[$i, $j]}"
        done
        echo
    done
    echo "---------------------------------------------------------------------------"

    echo "Ahora, ya toca calcular el TF x IDF de cada celda. Para ello hay que multiplicar el TF de cada celda por el IDF de la columna correspondiente, donde su valor está en la fila de abajo del todo."
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 3; j <= ncolumnas; j++)); do
            #matriz[$i,$j]=$(echo scale=2; "${matriz[$i,$j]} * ${matriz[$((nfilas+1)),$j]}" | bc -l)
            matriz2[$i, $j]=$(echo "scale=2; ${matriz2[$i, $j]} * ${matriz2[$((nfilas + 1)), $j]}" | bc)

        done
    done

    echo "Matriz con TF x IDF ya calculado para cada celda"
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 1; j <= ncolumnas; j++)); do
            printf "%3s|" "${matriz2[$i, $j]}"
        done
        echo
    done
    echo "---------------------------------------------------------------------------"

    echo "Calcular el TF medio y compararlo con 0.3:
<: es HAM, >: es SPAM"
    for ((i = 1; i <= nfilas; i++)); do

        suma=0
        mediaTF=0

        for ((j = 3; j <= ncolumnas; j++)); do
            suma=$(echo "scale=2; $suma+${matriz2[$i, $j]}" | bc)
        done

        if (($(bc <<<"$suma == 0.00"))); then
            matriz2[$i, $((ncolumnas + 1))]=0
        else
            mediaTF=$(echo "scale=2; $suma / $((ncolumnas - 2))" | bc -l)
            #echo "Suma: $suma"
            #echo "Media de correo $i: $mediaTF"
            #Si es mayor de 0.3, es HAM
            if (($(bc <<<"$mediaTF > 0.30"))); then #poner 0.3 cuando llegue
                matriz2[$i, $((ncolumnas + 1))]=1
            #Si no, es SPAM
            else
                matriz2[$i, $((ncolumnas + 1))]=0
            fi
        fi

    done

    ncolumnas=$((ncolumnas + 1))

    echo "Matriz FINAL"
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 1; j <= ncolumnas; j++)); do
            printf "%3s|" "${matriz2[$i, $j]}"
        done
        echo
    done

    #Guardar la matriz en el archivo con extension .tfdf
    for ((i = 1; i <= nfilas; i++)); do
        for ((j = 1; j <= ncolumnas; j++)); do
            echo -n "${matriz2[$i, $j]}" >>"$nombreFicheroFrecuencia.tfidf"
            if [ $j -lt $((ncolumnas)) ]; then
                echo -n ":" >>"$nombreFicheroFrecuencia.tfidf"
            else
                echo "" >>"$nombreFicheroFrecuencia.tfidf" # Nueva línea al final de cada fila
            fi
        done

    done

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------
function funcion_informe() {

    while true; do
        echo "3. Informes de resultados"
        echo "========================================================================================================"
        echo -e "En esta opción tienes 3 tipos diferentes de informe y dependiendo del número pulsado, escoges una. Las opciones son: \n"
        echo -e "\t1--> Informe en formato fila/columna donde por cada término muestre en cuantos correos electrónicos del 
conjunto de datos analizado aparece"
        echo -e "\t2--> Informe donde para un término particular, solicitado al usuario, se muestren los correos electrónicos 
donde aparece"
        echo -e "\t3-->* Dado un identificador de correo electrónico, mostrar cuantos términos de los analizados aparecen.\n"

        echo "========================================================================================================"
        echo "En las 3 opciones se va a pedir un fichero de frecuencias para poder realizar los informes correspondientes. Aparte, para 
no tener que pedir otra vez los ficheros de palabras y email, se usarán los que tienen el nombre predeterminado de la práctica: 
       --> Email: Emails.txt
       --> Términos --> Fraud_words.txt"
        echo "========================================================================================================"
        echo -n "Introduce un número (1, 2, 3 o 4 (salir)): "
        read numero

        if [ -z "$numero" ]; then
            echo "No has ingresado nada. Por favor, introduce un número."
        elif [[ ! "$numero" =~ ^[0-9]+$ ]]; then
            echo "Entrada no válida. Por favor, introduce un número válido."
        # Verificar si el número es 1, 2 o 3
        elif [ "$numero" -eq 1 ] || [ "$numero" -eq 2 ] || [ "$numero" -eq 3 ] || [ "$numero" -eq 4 ]; then

            #echo "Opción $numero escogida"
            echo "---------------------------------------------------------------------------------------------------------"
            if ((numero == 1)); then

                echo "1- Informe de formato fila/columna de un término."
                echo -n "Introduce el nombre del fichero de frecuencias(con la extensión): "
                read ficheroFrec_1

                if [ -z $ficheroFrec_1 ]; then

                    echo "No has introducido nada."

                elif [ -f $ficheroFrec_1 ]; then
                    echo "Existe el archivo $ficheroFrec_1"
                    #Cargar el contenido del archivo .freq en una matriz
                    declare -A matriz_aux1
                    indice=1

                    nfilas=$(cat $ficheroFrec_1 | wc -l)
                    #echo "Numero de filas: $nfilas"
                    ncolumnas=$(head -n 1 $ficheroFrec_1 | awk -F ":" {'print NF'})
                    #ncolumnas=$((ncolumnas - 3))
                    #echo "Numero de columnas: $ncolumnas"

                    while read linea; do
                        #echo "Línea $indice: $linea"
                        for ((j = 1; j <= ncolumnas; j++)); do
                            aux=$(echo $linea | cut -d':' -f$j)
                            #echo -n "$aux, "
                            matriz_aux1["$indice,$j"]=$aux
                        done
                        indice=$((indice + 1))
                    done <$ficheroFrec_1

                    ncolumnas=$((ncolumnas - 1)) #quitar la columna del tamaño de cada correo

                    #Buscar todos los no 0 de cada término en cada correo
                    for ((j = 3; j <= ncolumnas; j++)); do
                        matriz_aux1[$((nfilas + 1)), $j]=0 #Inicializo a 0 cada término
                    done
                    for ((i = 1; i <= nfilas; i++)); do
                        for ((j = 3; j <= ncolumnas; j++)); do
                            valor_matriz="${matriz_aux1[$i, $j]}"
                            if [ $valor_matriz -ne 0 ]; then #Ver las celdas que son diferente de 0
                                #echo "valor matriz = $valor_matriz"
                                matriz_aux1[$((nfilas + 1)), $j]=$((matriz_aux1[$((nfilas + 1)), $j] + 1))
                            fi
                        done
                    done

                    #            for ((j=3;j<=ncolumnas;j++)) do
                    #                printf "%3s|" "${matriz_aux1[$((nfilas+1)),$j]}"
                    #            done

                    array_aux=() #array para almacenar las palabras de spam (sword.txt)

                    while read linea; do
                        array_aux+=("$linea")
                    done <sword.txt
                    echo
                    printf "%-50s %-50s \n" "Término" "Nºveces que aparece"
                    echo "----------------------------------------------------------------------------------------"

                    contador=0
                    for ((j = 3; j <= ncolumnas; j++)); do

                        printf "%-50s %-50s \n" "${array_aux[j - 3]}" "${matriz_aux1[$((nfilas + 1)), $j]}"
                        ((contador++))
                        if [ $contador -eq 50 ]; then
                            read -p "Presiona Enter para mostrar las siguientes 50 líneas..."
                            contador=0
                        fi
                    done

                else
                    echo "El archivo $ficheroFrec_1 no existe"
                fi

            elif ((numero == 2)); then

                echo "2- Informe de un término en particular"

                echo -n "Introduce el nombre del fichero de frecuencias(con la extensión): "
                read ficheroFrec_2

                if [ -z $ficheroFrec_2 ]; then

                    echo "No has introducido nada."

                elif [ -f $ficheroFrec_2 ]; then

                    echo -n "Introduce el término a buscar en minúsculas y sin caracteres especiales: "
                    read termino

                    if [ -z "$termino" ]; then
                        echo "No has tecleado nada."

                    elif [[ "$termino" =~ ^[0-9]+$ ]]; then
                        echo "Se pide una palabra, no un número"
                    else
                        echo "Buscando $termino en el archivo Fraud_words.txt..."
                        #Cargar el contenido del archivo .freq en una matriz
                        declare -A matriz_aux2
                        indice=1

                        nfilas=$(cat $ficheroFrec_2 | wc -l)
                        #echo "Numero de filas: $nfilas"
                        ncolumnas=$(head -n 1 $ficheroFrec_2 | awk -F ":" {'print NF'})
                        #ncolumnas=$((ncolumnas - 3))
                        #echo "Numero de columnas: $ncolumnas"

                        while read linea; do
                            #echo "Línea $indice: $linea"
                            for ((j = 1; j <= ncolumnas; j++)); do
                                aux=$(echo $linea | cut -d':' -f$j)
                                #echo -n "$aux, "
                                matriz_aux2["$indice,$j"]=$aux
                            done
                            indice=$((indice + 1))
                        done <$ficheroFrec_2

                        ncolumnas=$((ncolumnas - 1)) #quitar la columna del tamaño de cada correo

                        #                echo "Visualizar la matriz cargada"
                        #                for ((i=1;i<=nfilas;i++)) do
                        #                    for ((j=1;j<=ncolumnas;j++)) do
                        #                        printf "%3s|" "${matriz_aux2[$i,$j]}"
                        #                    done
                        #                    echo
                        #                done

                        array_aux=()

                        while read linea; do
                            lineaaux=$(echo "$linea" | awk '{print tolower($0)}' | sed 's/[^[:alnum:]]/ /g')
                            array_aux+=("$lineaaux")
                        done <sword.txt

                        encontrado=0
                        posicion=-1
                        for ((i = 0; i < "${#array_aux[@]}"; i++)); do
                            if [ "${array_aux[i]}" = "$termino" ]; then
                                encontrado=1
                                posicion=$i
                                break
                            fi
                        done

                        if ((encontrado == 0)); then
                            echo "$termino no encontrado"
                        else
                            echo -e "\n$termino encontrado en la posición: $((posicion + 1)) de Fraud_words.txt\n" #posición - 1
                            posiciones_encontradas=()                                                              #Correos encontrados
                            for ((i = 1; i <= nfilas; i++)); do                                                    #Recorro cada fila buscando si el término de la columna: pos-1 es !=0
                                #echo "Verificando fila $i, posición $((posicion+1)): ${matriz_aux2[$i,$((posicion+3))]}" #Son 2 (2 columnas primeras) + 1 (indice del array)
                                #echo "este es: ${matriz_aux2[$i,$((posicion+3))]}"
                                if [ "${matriz_aux2[$i, $((posicion + 3))]}" != 0 ]; then
                                    #echo "entra"
                                    posiciones_encontradas+=("$i") # Agregar la posición actual de i al array
                                fi
                            done

                            echo -n "Posiciones: "
                            for palabra in "${posiciones_encontradas[@]}"; do
                                echo -n "$palabra | "
                            done

                            echo -e "\nBuscando en el archivo Emails.txt si aparece el término..."

                            if [ "${#posiciones_encontradas[@]}" != 0 ]; then

                                echo -e "\nEstá en ${#posiciones_encontradas[@]} correos.\n"

                                #Recorrer el archivo de los correos y mostrar solo aquellos que tengan las posiciones de mi array
                                printf "%-20s %-55s \n" "Índice del correo" "Contenido del correo"
                                echo "---------------------------------------------------------------------------"
                                indice_array=0 #contador para recorrer el array de posiciones encontradas del correo
                                for ((i = 1; i <= nfilas; i++)); do
                                    valor_array=${posiciones_encontradas[$indice_array]}
                                    if ((i == valor_array)); then                                           #si la posición  encontrada es igual a i
                                        correo_enc=$(awk -v linea="$i" 'NR==linea' Emails.txt | cut -c -50) # línea del correo
                                        printf "%-20s %-55s \n" "$i" "$correo_enc"
                                        indice_array=$((indice_array + 1)) #actualizo el array de posiciones solo si encuentra el correo

                                    fi
                                done
                            else
                                echo "El término no aparece en ningún correo de Email.txt"
                            fi

                        fi
                    fi

                else
                    echo "$ficheroFrec_2 no existe."
                fi

            elif ((numero == 3)); then

                echo "3- Informe número de términos en un correo"

                echo -n "Introduce el nombre del fichero de frecuencias(con la extensión): "
                read ficheroFrec_3

                if [ -z $ficheroFrec_3 ]; then

                    echo "No has introducido nada."

                elif [ -f $ficheroFrec_3 ]; then

                    echo "$ficheroFrec_3 existe."
                    echo -n "Introduce el identificador del correo: "
                    read identificador

                    if [ -z "$identificador" ]; then
                        echo "No has tecleado nada."
                    elif [[ ! "$identificador" =~ ^-?[0-9]+$ ]]; then
                        echo "Se pide un número ya sea positivo o negativo, no una palabra"

                    elif [ "$identificador" -lt 0 ]; then
                        echo "El id no puede ser negativo"
                    else
                        echo -e "Buscando $identificador en el archivo en la matriz...\n"
                        #Cargar el contenido del archivo .freq en una matriz
                        declare -A matriz_aux3
                        indice=1

                        nfilas=$(cat $ficheroFrec_3 | wc -l)
                        #echo "numero de filas: $nfilas"
                        ncolumnas=$(head -n 1 $ficheroFrec_3 | awk -F ":" {'print NF'})
                        #ncolumnas=$((ncolumnas - 3))
                        #echo "numero de columnas: $ncolumnas"

                        while read linea; do
                            #echo "Línea $indice: $linea"
                            for ((j = 1; j <= ncolumnas; j++)); do
                                aux=$(echo $linea | cut -d':' -f$j)
                                #echo -n "$aux, "
                                matriz_aux3["$indice,$j"]=$aux
                            done
                            indice=$((indice + 1))
                        done <$ficheroFrec_3

                        ncolumnas=$((ncolumnas - 1)) #quitar la columna del tamaño de cada correo

                        #                echo "Visualizar la matriz cargada"
                        #                for ((i=1;i<=nfilas;i++)) do
                        #                    for ((j=1;j<=ncolumnas;j++)) do
                        #                        printf "%3s|" "${matriz_aux3[$i,$j]}"
                        #                    done
                        #                    echo
                        #                done

                        if ((identificador > nfilas)) || ((identificador <= 0)); then
                            echo "El $identificador no pertenece a ningún identificador de correo."
                        else
                            echo -e "El identificador pertenece a un correo. Buscando las posiciones de los términos...\n"

                            terminos_encontrados=()
                            for ((j = 3; j <= ncolumnas; j++)); do
                                valor_t=${matriz_aux3[$identificador, $j]}
                                if [ "$valor_t" != 0 ]; then
                                    terminos_encontrados+=("$((j - 2))")
                                fi
                            done

                            if [ "${#terminos_encontrados[@]}" != 0 ]; then

                                echo -n "Posiciones: "
                                for palabra in "${terminos_encontrados[@]}"; do
                                    echo -n "$palabra | "
                                done

                                echo

                                echo -e "Hay un total de ${#terminos_encontrados[@]} palabras de spam en el correo con id: $identificador\n"
                                echo -n "--> Los términos son: "
                                for ((i = 0; i < ${#terminos_encontrados[@]}; i++)); do
                                    palabra_fraud_wordks=$(awk -v linea="${terminos_encontrados[i]}" 'NR==linea' sword.txt)
                                    echo -n "$palabra_fraud_wordks  |  "
                                done
                                echo
                            else
                                echo "No hay ninguna palabra de spam en el correo con id: $identificador"
                            fi

                        fi

                    fi

                else
                    echo "$ficheroFrec_3 no existe."
                fi

            else
                echo "Salir de la opcion"
                break
            fi

        else
            echo "Número no válido. Por favor, introduce 1, 2, 3 o 4."
        fi
        echo "Pulsa para continuar..."
        read p
        clear
    done

}
#-------------------------------------------------------------------------------------------------------------------------------------------------------
function funcion_prediccion() {

    while true; do
        echo "========================================================================================================"
        echo -e "Opción que calcula si un correo tiene spam o no. Se pide cargar un fichero de frecuencias ya creado o justo el generado por la opción 1 anteriormente:"
        echo -e "\t1 --> Opción para cargar la matriz después de hacer la opción 1"
        echo -e "\t2 --> Opción para cargar la matriz desde un archivo de frecuencias (.freq)"
        echo "========================================================================================================"
        echo -n "Introduce 1, 2 o 3(salir): "
        read opcion_prediccion

        if [ -z "$opcion_prediccion" ]; then
            echo "No has ingresado nada. Por favor, introduce un número."
        elif [[ ! "$opcion_prediccion" =~ ^[0-9]+$ ]]; then
            echo "Entrada no válida. Por favor, introduce un número válido."
        elif [ "$opcion_prediccion" == "1" ] || [ "$opcion_prediccion" == "2" ] || [ "$opcion_prediccion" == "3" ]; then

            #echo "Has elegido $opcion_prediccion"
            #Opcion posterior a opcion 1
            if ((opcion_prediccion == 1)); then
                echo "Hay que ver si se ha usado la opcion 1 previamente"
                if [ -z "$nombreResultado" ]; then
                    echo "No se ha usado todavía la opción análisis."
                else
                    #Empieza la opción 1
                    echo "Se ha utilzado la opcion 1: Existe el archivo creado anteriromente: $nombreResultado.freq"

                    nombreFicheroFrecuencias="$nombreResultado.freq"
                    #Cargar el contenido del archivo .freq en una matriz
                    declare -A matriz2
                    indice=1

                    nfilas=$(cat $nombreFicheroFrecuencias | wc -l)
                    echo "Numero de filas: $nfilas"
                    ncolumnas=$(head -n 1 $nombreFicheroFrecuencias | awk -F ":" {'print NF'})
                    #ncolumnas=$((ncolumnas - 3))
                    echo "Numero de columnas: $ncolumnas"

                    while read linea; do
                        #echo "Línea $indice: $linea"
                        for ((j = 1; j <= ncolumnas; j++)); do
                            aux=$(echo $linea | cut -d':' -f$j)
                            #echo -n "$aux, "
                            matriz2["$indice,$j"]=$aux
                        done
                        indice=$((indice + 1))
                    done <$nombreFicheroFrecuencias
                    calcular_tfidf $nfilas $ncolumnas matriz2 $nombreResultado #Aquí uso matriz, que es la variable de la opción 1

                fi

            #Opción de carga de archivo freq
            elif ((opcion_prediccion == 2)); then

                echo "Cargar el fichero de frecuencias con extensión .freq"
                read -p "Introduce el nombre del archivo de frecuencias (sin la extensión .freq): " nombreFicheroFrecuencia
                nombreFicheroFrecuencias="${nombreFicheroFrecuencia}.freq"
                extension=".freq"                           #borrar al final---------------------------------------------------------------
                if [ -f "$nombreFicheroFrecuencias" ]; then #Existe el archivo tecleado por el usuario

                    echo "Existe"

                    if [ -f "$nombreFicheroFrecuencia.tfidf" ]; then #Si existe el resultado sobre el archivo de frecuencias introducido, se pide al usuario si quiere realizar de nuevo el análisis de ese fichero de frecuencias o no
                        echo -e "Para este .freq ya se ha realizado la predicción.\nQuieres cargar la matriz TF-IDF y volver a hacer análisis de nuevo?:\n \t-->1: No hacer predicción y salir de la opción\n \t-->2: Cargar la matriz en memoria y hacer la predicción"
                        echo "-------------------------------------------------------------------------------------------------------------------------"
                        while true; do
                            echo -n "Introduce 1,2: "
                            read opcion_F

                            if [ -z "$opcion_F" ]; then
                                echo "No has ingresado nada. Por favor, introduce un número."
                            elif [[ ! "$opcion_F" =~ ^[0-9]+$ ]]; then
                                echo "Entrada no válida. Por favor, introduce un número válido."
                            elif [ "$opcion_F" == "1" ] || [ "$opcion_F" == "2" ]; then
                                break
                            else
                                echo "Numero no válido. Por favor, introduce 0 o 1."
                            fi
                        done

                        if ((opcion_F == 1)); then
                            echo "se ha introducido un 1. Saliendo de la opción..." #Aquí se sale de la opción
                        else

                            declare -A matriz_TFIDF
                            indice=1
                            nombreFicheroTFIDF="$nombreFicheroFrecuencia.tfidf"
                            nfilas=$(cat $nombreFicheroTFIDF | wc -l)
                            #echo "numero de filas: $nfilas"
                            ncolumnas=$(head -n 1 $nombreFicheroTFIDF | awk -F ":" {'print NF'})
                            #ncolumnas=$((ncolumnas - 3))
                            #echo "numero de columnas: $ncolumnas"

                            while read linea; do
                                #echo "Línea $indice: $linea"
                                for ((j = 1; j <= ncolumnas; j++)); do
                                    aux=$(echo $linea | cut -d':' -f$j)
                                    #echo -n "$aux, "
                                    matriz_TFIDF["$indice,$j"]=$aux
                                done
                                indice=$((indice + 1))
                            done <$nombreFicheroTFIDF

                            echo "Matriz TF-IDF cargada con éxito"

                            echo "Visualizar la matriz cargada"
                            for ((i = 1; i <= nfilas; i++)); do
                                for ((j = 1; j <= ncolumnas; j++)); do
                                    printf "%3s|" "${matriz_TFIDF[$i, $j]}"
                                done
                                echo
                            done

                            #echo "Borrando el archivo" #Aquí se vuelve a realizar la predicción
                            rm "$nombreFicheroFrecuencia.tfidf"
                            #Cargar el contenido del archivo .freq en una matriz
                            declare -A matriz2
                            indice=1

                            nfilas=$(cat $nombreFicheroFrecuencias | wc -l)
                            #echo "numero de filas: $nfilas"
                            ncolumnas=$(head -n 1 $nombreFicheroFrecuencias | awk -F ":" {'print NF'})
                            #ncolumnas=$((ncolumnas - 3))
                            #echo "numero de columnas: $ncolumnas"

                            while read linea; do
                                #echo "Línea $indice: $linea"
                                for ((j = 1; j <= ncolumnas; j++)); do
                                    aux=$(echo $linea | cut -d':' -f$j)
                                    #echo -n "$aux, "
                                    matriz2["$indice,$j"]=$aux
                                done
                                indice=$((indice + 1))
                            done <$nombreFicheroFrecuencias
                            calcular_tfidf $nfilas $ncolumnas matriz2 $nombreFicheroFrecuencia

                        fi

                    else
                        echo "No existe el archivo predicción" #Aquí se realiza la predicción
                        #Cargar el contenido del archivo .freq en una matriz
                        declare -A matriz2
                        indice=1

                        nfilas=$(cat $nombreFicheroFrecuencias | wc -l)
                        #echo "numero de filas: $nfilas"
                        ncolumnas=$(head -n 1 $nombreFicheroFrecuencias | awk -F ":" {'print NF'})
                        #ncolumnas=$((ncolumnas - 3))
                        #echo "numero de columnas: $ncolumnas"

                        while read linea; do
                            #echo "Línea $indice: $linea"
                            for ((j = 1; j <= ncolumnas; j++)); do
                                aux=$(echo $linea | cut -d':' -f$j)
                                #echo -n "$aux, "
                                matriz2["$indice,$j"]=$aux
                            done
                            indice=$((indice + 1))
                        done <$nombreFicheroFrecuencias

                        calcular_tfidf $nfilas $ncolumnas matriz2 $nombreFicheroFrecuencia
                    fi
                    #else de final de opcion 2.2
                else
                    echo "No existe el archivo $nombreFicheroFrecuencias. Saliendo de la opción 2."
                fi
            else
                echo "Saliendo de la opcion 2"
                break
            fi
        else
            echo "Numero no válido. Por favor, introduce 0 o 1."
        fi
        echo "Pulsa para continuar..."
        read p
        clear
    done
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------
function funcion_analisis() {

    echo "========================================================================================================"
    echo "En esta opción se pide 3 nombres: "
    echo -e "\t* Nombre del fichero en el que se encuentran las palabras o términos a buscar: (sword.txt)"
    echo -e "\t* Nombre del fichero donde se almacenan los correos electrónicos: (Emails.txt)"
    echo -e "\t* Nombre del fichero donde se desea almacenar el resultado del análisis (sin extensión)"
    echo "========================================================================================================"

    touch resultadoEmail.txt #Archivo temporal para guardar los correos corregidos
    touch resultadoWord.txt  #Archivo temporal para guardar las palabras corregidas

    echo "1 --> Nombre del fichero de palabras"
    echo -n "Por favor, introduce el nombre del fichero de palabras: "
    read nombrePalabras

    ficheroPalabras=sword.txt #Poner al final: swords.txt
    ficheroEmails=Emails.txt  #Poner al final: Emails.txt
    #nombre_fichero_P="$nombrePalabras"

    #Primer paso: fichero de palabras
    if [ -z "$nombrePalabras" ]; then
        echo "No has introducido nada. Vuelva a esta opción e ingresa un nombre válido"
    elif [ "$nombrePalabras" = "$ficheroPalabras" ] && [ -f "$nombrePalabras" ]; then #Existe y se llama swords.txt
        #echo "El fichero $nombrePalabras existe."

        echo "===================================================="
        #Segundo paso: fichero de emails
        echo "2 --> Nombre del fichero de correos"
        echo -n "Por favor, introduce el nombre del fichero de correos: "
        read nombreCorreo

        #nombre_fichero_C="$nombreCorreo.txt" #-----Quitar el .txt

        if [ -z "$nombreCorreo" ]; then
            echo "No has introducido nada. Vuelva a esta opción e ingresa un nombre válido"
        elif [ "$nombreCorreo" = "$ficheroEmails" ] && [ -f "$nombreCorreo" ]; then #Existe y se llama Emails.txt

            #echo "El fichero $nombre_fichero_C existe."

            echo "===================================================="
            #Tercer paso: fichero resultados
            echo "3 --> Nombre del fichero para guardar los resultados"
            echo -n "Por último, introduce el nombre del fichero resultados(solo el nombre): "
            read nombreResultado
            if [ -z "$nombreResultado.freq" ]; then
                echo "No has introducido nada. Vuelva a esta opción e ingresa un nombre válido"

            elif [ -e "$nombreResultado.freq" ]; then
                echo "El archivo $nombreResultado.freq ya existe en la carpeta actual."
            else
                # Si no existe, crear un nuevo archivo con el nombre ingresado y extensión .txt
                touch "$nombreResultado.freq"
                echo "Se ha creado el archivo $nombreResultado.freq en la carpeta actual."

                #---------------Aquí empieza el análisis. Primer paso, borrar los signos de puntuación, pasar a minúsculas y borrar todos los números del archivo de Emails.txt

                while read linea; do
                    linea_final=$(echo "$linea" | awk '{print tolower($0)}' | sed 's/[^[:alnum:]]/ /g' | sed 's/[0-9]//g')
                    echo "$linea_final" >>resultadoEmail.txt
                done <$nombreCorreo

                while read linea; do
                    linea_final=$(echo "$linea" | awk '{print tolower($0)}' | sed 's/[^[:alnum:]]/ /g')
                    echo "$linea_final" >>resultadoWord.txt
                done <$nombrePalabras

                nfilas=$(cat $nombreCorreo | wc -l)
                #echo "Numero de filas: $nfilas"

                ncolumnasT=$(cat $nombrePalabras | wc -l)
                ncolumnas=$((ncolumnasT + 2)) #Añadir las columnas de id y de spam o ham
                #echo "Numero de columnas: $ncolumnas"

                array=() #array para almacenar las palabras de spam (Fraud_words.txt)

                while read linea; do
                    array+=("$linea")
                done <resultadoWord.txt

                declare -A matriz #matriz para alamcenar los datos de ambos correos

                #Valor de 1 a N: identificador del correo
                for ((i = 1; i <= nfilas; i++)); do
                    # Asignar el valor de 'i' a la primera columna de la fila 'i'
                    matriz[$i, 1]=$i
                done

                #Asignar las ocurrencias de cada término en cada correo
                for ((i = 1; i <= nfilas; i++)); do
                    for ((j = 3; j <= ncolumnas; j++)); do

                        aux=$(awk -v linea="$i" 'NR==linea' resultadoEmail.txt) #aquí tengo la línea del correo
                        #echo "$aux"

                        aux2="${array[$j - 3]}" #aquí tengo la palabra detonante
                        #echo "palabra a buscar: $aux2"

                        cantidad=$(echo "$aux" | grep -o -i -w "$aux2" | wc -l) #número de coincidencias
                        #echo "Cantidad en $i de $aux2: $cantidad"
                        matriz[$i, $j]=$cantidad
                    done
                done

                #Hago una última columna para guardar el total de palabras de cada correo
                for ((i = 1; i <= nfilas; i++)); do
                    prueba=$(awk -v linea="$i" 'NR==linea' resultadoEmail.txt)
                    total=$(echo "$prueba" | wc -w)
                    #echo "Total palabras correo $i: $total"
                    matriz[$i, $((ncolumnas + 1))]=$total
                done

                #Por último, asigno a la segunda columna, el campo predicción: 2do campo del fichero correos
                for ((i = 1; i <= nfilas; i++)); do
                    predi=$(awk -v linea="$i" 'NR==linea' $nombreCorreo | cut -d '|' -f 3)
                    #echo "predi $i: $predi"
                    matriz[$i, 2]=$predi
                done
                echo "===================================================="
                echo "Análisis realizado con éxito"

                #Guardar la matriz en el archivo
                for ((i = 1; i <= nfilas; i++)); do
                    for ((j = 1; j <= ncolumnas + 1; j++)); do
                        echo -n "${matriz[$i, $j]}" >>$nombreResultado.freq
                        if [ $j -lt $((ncolumnas + 1)) ]; then
                            echo -n ":" >>$nombreResultado.freq
                        else
                            echo "" >>$nombreResultado.freq # Nueva línea al final de cada fila
                        fi
                    done

                done

                rm resultadoEmail.txt #borro ambos archivos una vez acabada la opción de análisis
                rm resultadoWord.txt
            fi

        else
            echo "El fichero $nombreCorreo no coincide con el nombre correcto ($ficheroEmails)."
        fi

    else
        echo "El fichero $nombrePalabras no coincide con el nombre correcto ($ficheroPalabras)."
    fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------
function funcion_ayuda() {

    echo -e "Manual de ayuda para poder utilizar la aplicación. Se va a dividir por opciones.\n"
    echo "================================================================================================================================================================================================================="
    echo -e "\nOpción 1: Análisis. \n\nIntroduce el fichero de correos, el fichero de palabras y el fichero de los resultados. Guarda todas las coincidencias de las palabras en el archivo de resultados en formato de matriz.\n"
    echo "================================================================================================================================================================================================================="
    echo -e "\nOpción 2: Predicción. \n\nCalcula mediante el algoritmo TF-IDF, si un correo tiene potencial de SPAM. Para ello, hay 2 opciones: \n"
    echo -e "\t-->2.1: Realiza la predicción si se ha hecho justo antes la opción 1 de análisis.\n"
    echo -e "\t-->2.2: Realiza la predicción de un fichero de frecuencias, pero hay varias opciones: \n\t\t-->2.2.1: Si no existe la predicción del propio fichero de frecuencias, se realiza la predicción.\n\t\t-->2.2.2: Si existe la predicción del propio fichero de frecuencias, se pide al usuario conformidad para ver si cargar la matriz TF-IDF en memoria\n"
    echo "================================================================================================================================================================================================================="
    echo -e "\nOpción 3: Informes.\n\nRealiza diferentes informes acerca de los resultados de un fichero de frecuencias. En las 3 opciones, debe introducirse el archivo de frecuencias, y se utilizan de manera predeterminada, los archivos de correos (Emails.txt) y palabras (sword.txt) para que el usuario no tenga que volver a introducirlos.\n"
    echo -e "\t-->3.1: Informe en formato fila/columna donde por cada término muestre en cuantos correos electrónicos del conjunto de datos analizado aparece"
    echo -e "\t-->3.2: Informe donde para un término particular, solicitado al usuario, se muestren los correos electrónicos donde aparece. Del correo electrónico sólo se mostrarán los 50 primeros caracteres"
    echo -e "\t-->3.3: Dado un identificador de correo electrónico, mostrar cuantos términos de los analizados aparecen\n"
    echo "================================================================================================================================================================================================================="
    echo -e "\nOpción 4: Ayuda\n\nManual de ayuda de la aplicación\n"
    echo "================================================================================================================================================================================================================="
    echo -e "\nOpción 5: Salir\n\nSalir de la aplicación\n "
    echo "================================================================================================================================================================================================================="
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------
clear
opcion=0

while [ $opcion -ne 5 ]; do
    echo "----------Menú de la Aplicación----------"
    echo "1. Análisis de datos"
    echo "2. Predicción"
    echo "3. Informes de resultados"
    echo "4. Ayuda"
    echo "5. Salir de la aplicación"

    echo -n "Opción: "
    read opcion

    clear

    case $opcion in

    1)
        echo "1. Análisis de datos"

        funcion_analisis
        ;;

    2)

        funcion_prediccion
        ;;

    3)

        funcion_informe

        ;;

    4)
        echo "4. Ayuda"

        funcion_ayuda
        ;;

    5)
        echo "5. Salir del programa"

        ;;

    *)
        echo "Opción incorrecta. Teclee un número válido: "
        opcion=0
        ;;

    esac
    echo "Pulsa para continuar..."
    read p
    clear
done
#-------------------------------------------------------------------------------------------------------------------------------------------------------
