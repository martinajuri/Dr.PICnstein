# Sistema de control de temperatura con display y corte automático tipo "pava eléctrica"

## Descripción general
Este proyecto simula el funcionamiento de una pava eléctrica con corte automático. Utiliza un microcontrolador PIC16F887 y emplea sus principales periféricos: entradas analógicas (ADC), salidas digitales, temporizadores, EUSART,  Watchdog.
El sistema mide la temperatura mediante un sensor analógico LM35, convierte la señal a digital con el ADC interno del PIC, y muestra la temperatura actual en displays de 7 segmentos. El usuario puede ingresar una temperatura de corte mediante un potenciometro lineal accediendo al modo ajuste mediante un pulsador para tal fin. Cuando la temperatura medida alcanza ese valor, se enciende un LED indicando que el sistema alcanzó el umbral, como si la pava se apagara.
Además, el sistema transmite los valores de temperatura y el umbral configurado mediante comunicación serie (UART), lo que permite visualizar y registrar datos desde una computadora u otro dispositivo conectado.

## Objetivos
- Utilizar el conversor A/D del PIC para leer las señales analógicas.
- Mostrar información en tiempo real en displays de 7 segmentos.
- Permitir al usuario interactuar mediante pulsadores y potenciómetro.
- Controlar un evento (encendido de LED) cuando se supera una temperatura establecida.
- Usar el watchdog para reiniciar el sistema ante un posible fallo.
- Implementar manejo entradas digitales y el display de forma multiplexada.
- Transmitir datos de temperatura por UART para monitoreo externo.

## Componentes a utilizar
- **Microcontrolador:** PIC16F887
- **Sensor de temperatura:** LM35 (salida analógica lineal, 10 mV/°C)
- **Display:** 3 dígitos de 7 segmentos, ánodo común
- **Teclado 3 teclas:** con los botones de un mouse en desuso
- **LEDs:** Indicador de temperatura alcanzada, calentando, modo seteo o ajuste y funcionando
- **Módulo UART o adaptador USB-Serial:** Para conexión con PC (por ejemplo, MAX232 o adaptador USB-TTL no incluidos)
- **Resistencias y transistores:** Para manejo de corriente de display y LEDs
- **Fuente de alimentación:** 5 V regulados provenientes de cualquier cargador de celular o puerto del PC
- **Cristal oscilador:** interno de 4 MHz (1 microsegundo/instrucción)
- **Capacitores, borneras, etc.

## Funcionamiento detallado

### Inicialización
- Se configuran los puertos, el ADC, EUSART y los periféricos necesarios.
- Se habilita el watchdog timer para reiniciar el sistema en caso de cuelgue.
- Los pines de los puertos no utilizados se configuran como salidas para evitar ruido de entrada

### Ajuste
  - Se ingresa en este modo pulsando el botón "AJUSTE"
  - Se lee mediante el ADC el valor de tensión que arroja el potenciómetro para setear la temperatura deseada  y se muestra esta en el display
  - Cuando se está conforme con el valor se vuelve a presionar "AJUSTE"

### Lectura de temperatura
  - El LM35 entrega una tensión proporcional a la temperatura (por ejemplo, 25°C → 250 mV).
  - El ADC del PIC convierte esa señal a un valor digital.
  - Se toman dos o tres muestras que se descartan al iniciar el proceso de toma de temperatura
  - Luego se toman 10 muestras y se promedian (en realidad se suman y luego con el punto decimal se hace una división por diez "virtual", o sea corriendo la coma)

### Visualización
  - El valor de temperatura se muestra en un display de 3 dígitos con un decimal (ej. "27.5"). Esto sería el resultado de sumar 27.5 10 veces, o sea 275 con el punto en el segundo display.

### Configuración del umbral
  - El usuario ingresa la temperatura deseada pulsando el boton "AJUSTE" y ajutando con el potenciometro lineal el valor (por ejemplo, 80°C).

### Control
  Una vez iniciado el funcionamiento pulsando el boton "INICIAR/PARAR"
  - Si la temperatura medida ≥ temperatura de corte, se apaga un LED como señal de "apagado automático".
  - Si no, el LED permanece prendido.

### Detenido
  - Si estando en funcionamiento se pulsa el botón "INICIAR/PARAR", se apaga el LED que indica "calentando".
    (La temperatura puede seguirse mostrando)

### Transmisión UART
  - Cada cierto intervalo (por ejemplo, cada segundo), el sistema envía por UART:

  ```
  Temp: 27.5°C | Corte: 80°C
  ```

  Esto permite monitorear desde una PC usando un programa como PuTTY o un script en Python.

  - El uso del oscilador interno a 4MHz hace que se pueda transmitir a velocidades standard de 9600,19200, o 115200 baudios comodamente

### Reseteo por watchdog
  - Si el programa queda colgado por alguna falla, el watchdog lo reinicia.

### Opcionales

#### Vref:
  - La tensión Vref del conversor A/D puede setearse mediante un potenciometro multivuelta que alimenta AN3/Vref+. El conversor es de 10 bits, o sea de 0 a 1023 cuentas.
  Ajustado el A/D para usar AN3/Vref como referencia positiva (+) y la masa como referencia negativa(-) serviría para tener el fondo de escala del conversor A/D regulable(incluso si el sensor estuviera descalibrado se puede ajustar la ganancia de manera que cada incremento del A/D corresponda a 0,1°C o incluso para pruebas se puede bajar esta tensión y hacer que por ej los 36° del cuerpo se vean como 100°C o similar).
  Por ej: si seteamos el fondo en 1,024V cada salto o paso del conversor será de 1mV y como el LM35 varía de a 10mV/°C tendríamos una resolución posible de 1mv, o sea 0,1°C y un rango dinámico de 0 a 100°C.

  La fórmula es:
    Vref+ = Vcc * R2 / (R1 + R2)

  Para Vcc = 5V y Vref+ = 1.024V:
    1.024 = 5 * R2 / (R1 + R2)
    1.024 * (R1 + R2) = 5 * R2
    1.024 * R1 = 5 * R2 - 1.024 * R2
    1.024 * R1 = R2 * (5 - 1.024)
    R1/R2 = (5 - 1.024) / 1.024 ≈ 3.88

  Por ejemplo:
    R2 = 10kΩ → R1 ≈ 38.8kΩ (podés usar 39kΩ estándar)
    Colocá un capacitor de 0.1 μF (100 nF) entre Vref+ y GND para filtrar.

#### Nota
  Si por el contrario se usa con Vref=5V o sea VDD la resolución sería 5V/1024=0,0048828125 V=0,48mV, o sea casi 0,5°C lo cual no está nada mal y el rango de 0 a unos hipotéticos 500°C (en realidad el LM35 va solo hasta 155°C). Esta opción podría usarse para una resolución de medio grado si se prefiere simplicidad.

### Potenciometro lineal

  - A la entrada AN0 se conecta un cursor hecho con un potenciometro lineal que puede variar la tensión de entrada al conversor A/D de 0 a 5V. Esta tensión determinará el valor deseado o setpoint cuando se esté en el modo ajuste.
  Al pasar a modo ajuste la tensión Vref+ se ajusta Vdd y luego de obtener el setpoint, se vuelve a la Vref opcional de 1,024V. Esto se hace por soft y hay que esperar a que el A/D se estabilice.


