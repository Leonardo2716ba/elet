//`timescale 1ns / 1ps

module motor_4tempos (
    input clk,               // Clock principal (100MHz)
    input reset,             // Sinal de reset
    output reg [3:0] estado_cilindro1,  // Estados do cilindro 1
    output reg [3:0] estado_cilindro2,  // Estados do cilindro 2
    output reg [12:0] rpm               // Valor de RPM (0-8000)
);

// Estados representados com shift de bits
parameter ADMISSAO   = 4'b1000;  // 1000
parameter COMPRESSAO = 4'b0100;  // 0100
parameter IGNICAO    = 4'b0010;  // 0010
parameter EXAUSTAO   = 4'b0001;  // 0001

reg [12:0] rpm_target = 0;
reg [31:0] counter_ign = 0;  // Contador de ignições

// Lógica principal de controle do motor
always @(posedge clk or posedge reset) begin
    if (reset) begin
        estado_cilindro1 <= ADMISSAO;
        estado_cilindro2 <= IGNICAO;
        rpm <= 0;
        rpm_target <= 0;
        counter_ign <= 0;
    end else begin
        // Shift para próximo estado (Cilindro 1)
        case (estado_cilindro1)
            ADMISSAO:   estado_cilindro1 <= COMPRESSAO;
            COMPRESSAO: estado_cilindro1 <= IGNICAO;
            IGNICAO:    estado_cilindro1 <= EXAUSTAO;
            EXAUSTAO:   estado_cilindro1 <= ADMISSAO;
            default:    estado_cilindro1 <= ADMISSAO;
        endcase
        
        // Shift para próximo estado (Cilindro 2)
        case (estado_cilindro2)
            ADMISSAO:   estado_cilindro2 <= COMPRESSAO;
            COMPRESSAO: estado_cilindro2 <= IGNICAO;
            IGNICAO:    estado_cilindro2 <= EXAUSTAO;
            EXAUSTAO:   estado_cilindro2 <= ADMISSAO;
            default:    estado_cilindro2 <= ADMISSAO;
        endcase

        // Contador de ignições para incremento de RPM
        counter_ign <= counter_ign + 1;
        if (counter_ign >= 2) begin
            counter_ign <= 0;
            if (rpm_target < 8000) begin
                rpm_target <= rpm_target + 100;
            end
        end

        // Atualiza RPM gradualmente
        if (rpm < rpm_target) begin
            rpm <= rpm + 1;
        end else if (rpm > rpm_target) begin
            rpm <= rpm - 1;
        end
    end
end

endmodule


// ==============================================
// Testbench para validar o funcionamento
// ==============================================
module tb_motor_4tempos();
    reg clk;
    reg reset;
    wire [3:0] estado_cilindro1;
    wire [3:0] estado_cilindro2;
    wire [12:0] rpm;
    
    motor_4tempos uut (
        .clk(clk),
        .reset(reset),
        .estado_cilindro1(estado_cilindro1),
        .estado_cilindro2(estado_cilindro2),
        .rpm(rpm)
    );
    
    // Clock de 100MHz (10ns período)
    always #5 clk = ~clk;
    
    initial begin
        // Inicialização
        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        // Monitoramento contínuo
        repeat (5720) begin
            #14;
            $display("Tempo: %t | C1: %b | C2: %b | RPM: %d", 
                     $time, estado_cilindro1, estado_cilindro2, rpm);
        end

        $display("\nTeste concluído!");
        $finish;
    end
endmodule
