# Sistema de control de temperatura con display, teclado y corte automático tipo "pava eléctrica"

## Descripción general
Este proyecto simula el funcionamiento de una pava eléctrica con corte automático. Utiliza un microcontrolador PIC16F887 y emplea sus principales periféricos: entradas analógicas (ADC), salidas digitales, teclado matricial, display de 7 segmentos y el temporizador Watchdog.  
El sistema mide la temperatura mediante un sensor analógico (como el LM35), convierte la señal a digital con el ADC interno del PIC, y muestra la temperatura actual en dos display de 7 segmentos. El usuario puede ingresar una temperatura de corte mediante un teclado matricial. Cuando la temperatura medida supera ese valor, se enciende un LED indicando que el sistema alcanzó el umbral, como si la pava se apagará.  
Además, el sistema transmite los valores de temperatura y el umbral configurado mediante comunicación serie (UART), lo que permite visualizar y registrar datos desde una computadora u otro dispositivo.

## Objetivos
- Utilizar el conversor A/D del PIC para leer una señal analógica.
- Mostrar información en tiempo real en un display de 7 segmentos.
- Permitir al usuario interactuar mediante un teclado matricial.
- Controlar un evento (encendido de LED) cuando se supera una temperatura establecida.
- Usar el watchdog para reiniciar el sistema ante un posible fallo.
- Implementar manejo de teclado y display de forma multiplexada.
- Transmitir datos de temperatura por UART para monitoreo externo.

## Componentes a utilizar
- **Microcontrolador:** PIC16F877
- **Sensor de temperatura:** LM35 (salida analógica lineal, 10 mV/°C)
- **Display:** 2 dígitos de 7 segmentos, cátodo común
- **Teclado matricial:** 4x4
- **LED:** Indicador de temperatura superada
- **Módulo UART o adaptador USB-Serial:** Para conexión con PC (por ejemplo, MAX232 o adaptador USB-TTL)
- **Resistencias y transistores:** Para manejo de corriente de display y LED
- **Fuente de alimentación:** 5 V regulados
- **Cristal oscilador:** 4–20 MHz
- **Capacitores, zócalo, pulsador de reset, etc.

## Funcionamiento detallado

### Inicialización
- Se configuran los puertos, el ADC, UART y los periféricos necesarios.
- Se habilita el watchdog timer para reiniciar el sistema en caso de cuelgue.

### Lectura de temperatura
- El LM35 entrega una tensión proporcional a la temperatura (por ejemplo, 25°C → 250 mV).
- El ADC del PIC convierte esa señal a un valor digital.

### Visualización
- El valor de temperatura se muestra en un display de 2 dígitos (ej. "27").

### Configuración del umbral
- El usuario ingresa la temperatura deseada usando el teclado (por ejemplo, 80°C).

### Control
- Si la temperatura medida ≥ temperatura de corte, se apaga un LED como señal de "apagado automático".
- Si no, el LED permanece prendido.

### Transmisión UART
- Cada cierto intervalo (por ejemplo, cada segundo), el sistema envía por UART:

  ```
  Temp: 27°C | Corte: 80°C
  ```

  Esto permite monitorear desde una PC usando un programa como PuTTY o un script en Python.

### Reseteo por watchdog
- Si el programa queda colgado por alguna falla, el watchdog lo reinicia.
