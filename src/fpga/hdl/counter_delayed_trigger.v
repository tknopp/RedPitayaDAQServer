`timescale 1ns / 1ps

module counter_delayed_trigger #
(
    parameter integer TRIGGER_WIDTH = 32,
	parameter integer TRIGGER_PRESAMPLES_WIDTH = 32
)
(
    input clk,
	input aresetn,
	input trigger_arm, // Arm the trigger
	input trigger_reset, // Unset the trigger after having triggered. Needs re-arming then.
    input counter_reset, // Reset the counter to zero and save last counter state.
	input [TRIGGER_PRESAMPLES_WIDTH-1:0] trigger_presamples, // Number of samples the trigger should be fired prior to reaching the last counter value
    output trigger,
	output trigger_armed // Arming status of the trigger
);

// Delayed trigger counter
reg [TRIGGER_WIDTH-1:0] delayed_trigger_counter = 0;
reg [TRIGGER_WIDTH-1:0] last_counter_out = 0;
reg counter_reset_first = 0;
reg trigger_out = 0;
reg trigger_armed_int = 0;

always @(posedge clk)
begin
	if (~aresetn)
	begin
		// Only react on first reset == 1
		if ((counter_reset == 1) && (counter_reset_first == 1))
		begin
			last_counter_out <= delayed_trigger_counter;
			delayed_trigger_counter <= 0;
			counter_reset_first <= 0;
		end
		else
		begin
			delayed_trigger_counter <= delayed_trigger_counter + 1;
			
			if (counter_reset == 0 && counter_reset_first == 0)
			begin
				counter_reset_first <= 1;
			end
		end
		
		// Set trigger if armed and presamples reached
		if ((trigger_armed_int == 1) && (delayed_trigger_counter >= last_counter_out-trigger_presamples-1))
		begin
			trigger_out <= 1;
		end
		else
		begin
			if (trigger_reset == 1)
			begin
				trigger_out <= 0;
				trigger_armed_int <= 0;
			end
			else
			begin
				// React to trigger arming internally in order to allow for short arm pulses
				if (trigger_arm == 1)
				begin
					trigger_armed_int <= 1;
				end
			end
		end
	end
	else
	begin
		delayed_trigger_counter <= 0;
		last_counter_out <= 0;
		counter_reset_first <= 0;
		trigger_out <= 0;
		trigger_armed_int <= 0;
	end
end

assign trigger = trigger_out;
assign trigger_armed = trigger_armed_int;

endmodule
