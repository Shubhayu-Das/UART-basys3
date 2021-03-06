#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2019.1 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Sat Nov 27 12:24:46 IST 2021
# SW Build 2552052 on Fri May 24 14:47:09 MDT 2019
#
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
echo "xsim tb_uart_tx_behav -key {Behavioral:tx_sim:Functional:tb_uart_tx} -tclbatch tb_uart_tx.tcl -view /home/shubhayu/Sem 7/FPGA/Vivado/UART_RX_TX/tb_uart_tx_behav.wcfg -log simulate.log"
xsim tb_uart_tx_behav -key {Behavioral:tx_sim:Functional:tb_uart_tx} -tclbatch tb_uart_tx.tcl -view /home/shubhayu/Sem 7/FPGA/Vivado/UART_RX_TX/tb_uart_tx_behav.wcfg -log simulate.log

