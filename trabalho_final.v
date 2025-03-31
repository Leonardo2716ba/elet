/*
 * Sistema completo de controle para motor 4 tempos com 2 cilindros
 * Com RPM incrementado a cada ignição (até 8000 RPM)
 */

`timescale 1ns / 1ps

module motor_4tempos (
    input clk,               // Clock principal (100MHz)
    input reset,             // Sinal de reset
    input sensor_volta,      // Pulso do sensor (1 por volta completa)
    output reg [1:0] adm,    // Válvulas de admissão
    output reg [1:0] exh,    // Válvulas de exaustão
    output reg [1:0] ign,    // Ignição das velas
    output reg [12:0] rpm    // Valor de RPM (0-8000)
);

// Estados do motor de 4 tempos
parameter ADMISSAO  = 2'b00;
parameter COMPRESSAO = 2'b01;
parameter EXPLOSAO   = 2'b10;
parameter exaus     = 2'b11;

reg [1:0] estado_cilindro1;
reg [1:0] estado_cilindro2;
reg [3:0] contador_tempos;
reg [12:0] rpm_target = 0;  // RPM desejado
reg [31:0] counter_ign = 0;  // Contador de ignições

// Lógica principal de controle do motor
always @(posedge clk or posedge reset) begin
    if (reset) begin
        estado_cilindro1 <= ADMISSAO;
        estado_cilindro2 <= EXPLOSAO;
        contador_tempos <= 0;
        adm <= 2'b10;
        exh <= 2'b00;
        ign <= 2'b00;
        rpm <= 0;
        rpm_target <= 0;
        counter_ign <= 0;
    end else begin
        contador_tempos <= contador_tempos + 1;
        
        // Máquina de estados - Cilindro 1
        case(estado_cilindro1)
            ADMISSAO: begin
                adm[0] <= 1;
                if (contador_tempos == 4'b1111) estado_cilindro1 <= COMPRESSAO;
            end
            COMPRESSAO: begin
                adm[0] <= 0;
                if (contador_tempos == 4'b1111) begin
                    estado_cilindro1 <= EXPLOSAO;
                    ign[0] <= 1;
                    counter_ign <= counter_ign + 1;
                end
            end
            EXPLOSAO: begin
                ign[0] <= 0;
                if (contador_tempos == 4'b1111) estado_cilindro1 <= exaus;
            end
            exaus: begin
                exh[0] <= 1;
                if (contador_tempos == 4'b1111) begin
                    estado_cilindro1 <= ADMISSAO;
                    exh[0] <= 0;
                end
            end
        endcase
        
        // Máquina de estados - Cilindro 2
        case(estado_cilindro2)
            ADMISSAO: begin
                adm[1] <= 1;
                if (contador_tempos == 4'b1111) estado_cilindro2 <= COMPRESSAO;
            end
            COMPRESSAO: begin
                adm[1] <= 0;
                if (contador_tempos == 4'b1111) begin
                    estado_cilindro2 <= EXPLOSAO;
                    ign[1] <= 1;
                    counter_ign <= counter_ign + 1;
                end
            end
            EXPLOSAO: begin
                ign[1] <= 0;
                if (contador_tempos == 4'b1111) estado_cilindro2 <= exaus;
            end
            exaus: begin
                exh[1] <= 1;
                if (contador_tempos == 4'b1111) begin
                    estado_cilindro2 <= ADMISSAO;
                    exh[1] <= 0;
                end
            end
        endcase
        
        // Incrementa RPM a cada 16 ignições
        if (counter_ign >= 2) begin
            counter_ign <= 0;
            if (rpm_target < 8000) begin
                rpm_target <= rpm_target + 100; // Incremento de 100 RPM
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
// Testbench com monitoramento completo
// ==============================================
module tb_motor_4tempos();

    reg clk;
    reg reset;
    reg sensor_volta;
    
    wire [1:0] adm;
    wire [1:0] exh;
    wire [1:0] ign;
    wire [12:0] rpm;
    
    motor_4tempos uut (
        .clk(clk),
        .reset(reset),
        .sensor_volta(sensor_volta),
        .adm(adm),
        .exh(exh),
        .ign(ign),
        .rpm(rpm)
    );
    
    // Clock de 100MHz (10ns período)
    always #5 clk = ~clk;
    
    function [39:0] get_estagio;
        input [1:0] estado;
        begin
            case(estado)
                2'b00: get_estagio = "Admiss"; 
                2'b01: get_estagio = "Compre";
                2'b10: get_estagio = "Explos";  
                2'b11: get_estagio = "exaus";  
                default: get_estagio = "Unknow";
            endcase
        end
    endfunction
    
    initial begin
        // Inicialização
        clk = 0;
        reset = 1;
        sensor_volta = 0;
        
        $display("\nIniciando simulação com RPM incrementado por ignição");
        $display("Formato: Tempo | C1(Estágio) Adm/Exh/Ign | C2(Estágio) Adm/Exh/Ign | RPM");
        $display("========================================================================");
        
        // Espera para o sinal percorrer todo o circuito
        #100;
        reset = 0;
        
        // Monitoramento contínuo
        forever begin
            #1000; // Atualiza a cada 1us
            $display("T: %t ns | C1(%s) A%d E%d I%d | C2(%s) A%d E%d I%d | RPM: %d",
                    $time, 
                    get_estagio(uut.estado_cilindro1), uut.adm[0], uut.exh[0], uut.ign[0],
                    get_estagio(uut.estado_cilindro2), uut.adm[1], uut.exh[1], uut.ign[1], 
                    uut.rpm);
        end
    end
    
    initial begin
        #90_000; // 50ms
        $display("\nTeste concluído com sucesso!");
        $finish;
    end

endmodule