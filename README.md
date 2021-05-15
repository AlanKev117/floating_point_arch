# floating_point_arch
Arquitectura de punto flotante escrita en VHDL.

## Set de instrucciones


| Instruccion | 13:10 | 9:8 | 7:0 |
|---|---|---|---|
| Cargar byte en AX | 0000 | byte de AX | valor del byte |
| Mover AX a registro | 0001 | numero de registro | X |
| Mover registro a AX | 0010 | numero de registro | X |


| Instruccion | 13:10 | 9:8 | 7:6 | 5:0 |
|---|---|---|---|---|
| Sumar dos registros y guardar resultado en AX | 0011 | primer registro | segundo registro | X |
| Restar dos registros y guardar resultado en AX | 0100 | primer registro | segundo registro | X |
| Multiplicar dos registros y guardar resultado en AX | 0101 | primer registro | segundo registro | X |
| Dividir dos registros y guardar resultado en AX | 0110 | primer registro | segundo registro | X |
| AND entre dos registros y guardar resultado en AX | 0111 | primer registro | segundo registro | X |
| OR entre dos registros y guardar resultado en AX | 1000 | primer registro | segundo registro | X |
| XOR entre dos registros y guardar resultado en AX | 1001 | primer registro | segundo registro | X |

| Instruccion | 13:10 | 9:8 | 7:5 | 4:0 |
|---|---|---|---|---|
| Limpiar un bit de un registro | 1010 | registro | X | posición de bit |
| Fijar un bit de un registro | 1011 | registro | X | posición de bit |
