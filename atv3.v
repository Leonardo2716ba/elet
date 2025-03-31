module timer_control(
    input clk,
    input reset,
    input campo,
    input set,
    input enable_disable,
    input evento,
    output reg S,
    output reg [6:0] display_dezena,
    output reg [6:0] display_unidade,
    output wire led_dezena,
    output wire led_unidade,
    output reg led_estado
);
    
    reg [3:0] dezena = 4'd0;
    reg [3:0] unidade = 4'd0;
    reg ativo = 0;
    reg campo_sel = 0;
    reg [15:0] contador;
    reg contando = 0;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ativo <= 0;
            S <= 0;
            contando <= 0;
            contador <= 0;
            dezena <= 0;
            unidade <= 0;
        end else begin
            if (enable_disable)
                ativo <= ~ativo;
            
            led_estado <= ativo;
            
            if (!ativo) begin
                if (campo) begin
                    campo_sel <= ~campo_sel;
                end
                
                if (set) begin
                    if (!campo_sel) begin
                        if (dezena < 9) dezena <= dezena + 1;
                    end else begin
                        if (unidade < 9) unidade <= unidade + 1;
                    end
                end
            end else begin
                if (evento && !contando) begin
                    contando <= 1;
                    S <= 1;
                    contador <= (dezena * 10 + unidade) * 60_000; // Tempo em milissegundos
                end
                
                if (contando) begin
                    if (contador > 0) contador <= contador - 1;
                    else begin
                        contando <= 0;
                        S <= 0;
                    end
                end
            end
        end
    end
    
    assign led_dezena = ~campo_sel;
    assign led_unidade = campo_sel;
    
    function [6:0] seg_display;
        input [3:0] num;
        case(num)
            4'd0: seg_display = 7'b0111111;
            4'd1: seg_display = 7'b0000110;
            4'd2: seg_display = 7'b1011011;
            4'd3: seg_display = 7'b1001111;
            4'd4: seg_display = 7'b1100110;
            4'd5: seg_display = 7'b1101101;
            4'd6: seg_display = 7'b1111101;
            4'd7: seg_display = 7'b0000111;
            4'd8: seg_display = 7'b1111111;
            4'd9: seg_display = 7'b1101111;
            default: seg_display = 7'b0000000;
        endcase
    endfunction
    
    always @(*) begin
        display_dezena = seg_display(dezena);
        display_unidade = seg_display(unidade);
    end
    
endmodule

//`timescale 1ns / 1ps
module timer_control_tb;
    reg clk;
    reg reset;
    reg campo;
    reg set;
    reg enable_disable;
    reg evento;
    wire S;
    wire [6:0] display_dezena;
    wire [6:0] display_unidade;
    wire led_dezena;
    wire led_unidade;
    wire led_estado;
    
    timer_control uut (
        .clk(clk),
        .reset(reset),
        .campo(campo),
        .set(set),
        .enable_disable(enable_disable),
        .evento(evento),
        .S(S),
        .display_dezena(display_dezena),
        .display_unidade(display_unidade),
        .led_dezena(led_dezena),
        .led_unidade(led_unidade),
        .led_estado(led_estado)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        campo = 0;
        set = 0;
        enable_disable = 0;
        evento = 0;

        // Monitoramento dos sinais
        $monitor("Tempo=%0t | Dezena=%d | Unidade=%d | Campo_sel=%b | Set=%b | Led_dezena=%b | Led_unidade=%b", 
                $time, uut.dezena, uut.unidade, uut.campo_sel, set, led_dezena, led_unidade);

        // Mensagem inicial
        $display("=== Início da Simulação ===");

        #1000 reset = 0;
        $display("[RESET] Sistema resetado");

        #1000 enable_disable = 1;
        #1000 enable_disable = 0;
        $display("[ENABLE] Sistema ativado");

        #10 campo = 1; #1000 campo = 0;
        $display("[CAMPO] Alternando campo");

        #10 campo = 1; #10 campo = 0;
        #10 set = 1; #10 set = 0;  // Incrementa dezena
        
        #10 set = 1; #1000 set = 0;
        $display("[SET] Incrementando valor selecionado");
        #10 campo = 1; #10 campo = 0;
        #100 set = 1; #1000 set = 0;  // Incrementa unidade


        #1000 campo = 1; #1000 campo = 0;
        $display("[CAMPO] Alternando campo novamente");

        #1000 set = 1; #1000 set = 0;
        $display("[SET] Incrementando novamente");

        #10 evento = 1; #1000 evento = 0;
        $display("[EVENTO] Evento acionado");

        #2000000;

        $display("=== Fim da Simulação ===");
        $finish;
    end
endmodule

