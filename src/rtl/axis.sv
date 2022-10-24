// axis.sv - Reed Foster
// axi-stream interface

interface Axis_If #(
  parameter int DWIDTH = 32
);

logic [DWIDTH - 1:0]  data;
logic                 ready;
logic                 valid;
logic                 last;

modport Master (
  input   ready,
  output  valid,
  output  data,
  output  last
);

modport Slave (
  output  ready,
  input   valid,
  input   data,
  input   last
);

endinterface
