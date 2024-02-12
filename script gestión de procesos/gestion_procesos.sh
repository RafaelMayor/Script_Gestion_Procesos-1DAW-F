#!/bin/bash

################################
#
# Nombre: gestion_procesos.sh
# Autor: Rafael Martín Mayor <rmarmay2004@gmail.com>
#
# Objetivo: Gestionado de procesos
#
# Entradas: Máximo uso de CPU y memoria.
# Salidas: Gestionado de procesos.
#
# Historial:
#   2024-02-12: versión final
#
################################


# Verificar la cantidad de argumentos
if [ "$#" -ne 2 ]; then
  echo "Error: Se deben proporcionar dos argumentos."
  echo "Uso: $0 <maxCPU> <maxMem>"
  exit 100
fi

# Verificar que ambos valores sean mayores o iguales a 0
if [ "$1" -lt 0 ] || [ "$2" -lt 0 ]; then
  echo "Error: Ambos valores deben ser mayores o iguales a 0."
  exit 200
fi

# Verificar que maxMem sea menor o igual a 100
if [ "$2" -gt 100 ]; then
  echo "Error: maxMem debe ser menor o igual a 100."
  exit 150
fi

# Función para manejar las señales
handle_signals() {
  case $1 in
    INT)
      echo "Interrumpiendo ejecución"
      exit 0
      ;;
    TERM)
      echo "Finalizando ejecución"
      exit 0
      ;;
    USR1)
      echo "Mostrando carga del sistema:"
      uptime
      ;;
    USR2)
      echo "Mostrando límites de procesos del sistema:"
      ulimit -a
      ;;
  esac
}

# Asociar la función de manejo de señales a las señales correspondientes
trap 'handle_signals INT' INT
trap 'handle_signals TERM' TERM
trap 'handle_signals USR1' USR1
trap 'handle_signals USR2' USR2

# Bucle principal
while true; do
  # Obtener el proceso con mayor %CPU
  max_cpu_process=$(ps -eo pid,%cpu,comm --sort=-%cpu | awk 'NR==2 {print $1}')
  cpu_percentage=$(ps -eo pid,%cpu,comm --sort=-%cpu | awk 'NR==2 {print $2}')

  # Obtener el proceso con mayor %MEM
  max_mem_process=$(ps -eo pid,%mem,comm --sort=-%mem | awk 'NR==2 {print $1}')
  mem_percentage=$(ps -eo pid,%mem,comm --sort=-%mem | awk 'NR==2 {print $2}')

  # Verificar si algún proceso supera los límites
  if [ "$cpu_percentage" -gt "$1" ] || [ "$mem_percentage" -gt "$2" ]; then
    echo "Proceso que supera los límites:"
    ps -p $max_cpu_process -o pid,%cpu,%mem,comm
    echo "Opciones:"
    echo "1. Ignorar el aviso y seguir comprobando"
    echo "2. Disminuir en 3 puntos la prioridad del proceso"
    echo "3. Interrumpir el proceso"
    echo "4. Terminar el proceso"
    echo "5. Finalizar inmediatamente el proceso"
    echo "6. Detener el proceso (evitable)"
    echo "7. Detener el proceso (inevitable)"

    read -p "Selecciona una opción (1-7): " option

    case $option in
      1)
        echo "Ignorando el aviso. Continuando comprobación."
        ;;
      2)
        renice +3 -p $max_cpu_process
        echo "Prioridad del proceso reducida en 3 puntos."
        ;;
      3)
        kill -INT $max_cpu_process
        echo "Proceso interrumpido."
        ;;
      4)
        kill -TERM $max_cpu_process
        echo "Proceso terminado."
        ;;
      5)
        kill -KILL $max_cpu_process
        echo "Proceso terminado inmediatamente."
        ;;
      6)
        kill -STOP $max_cpu_process
        echo "Proceso detenido (evitable)."
        ;;
      7)
        kill -KILL $max_cpu_process
        echo "Proceso detenido (inevitable)."
        ;;
      *)
        echo "Opción no válida."
        ;;
    esac
  fi

  # Esperar 30 segundos antes de la siguiente comprobación
  sleep 30
done
