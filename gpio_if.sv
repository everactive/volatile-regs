`ifndef GPIO_IF_SV
`define GPIO_IF_SV

interface gpio_if();
   wire [7:0] gpi;
   wire [7:0] gpo;
endinterface : gpio_if

typedef virtual gpio_if gpio_vif;

`endif // GPIO_IF_SV
