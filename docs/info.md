<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

# How it works

The SmartSense Energy Management System monitors occupancy using PIR and IR sensors. A finite state machine determines room occupancy and controls appliance relays accordingly. Energy consumption is accumulated over time for both smart and conventional operation to estimate energy savings.

## How to test

# How to test

1. Apply a clock and reset.
2. Drive ui_in[0] to simulate the PIR sensor.
3. Drive ui_in[1] to simulate the IR sensor.
4. Observe:
   - uo_out[0] = Light relay
   - uo_out[1] = Fan relay
   - uo_out[2] = AC relay
   - uo_out[4:3] = FSM state

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
