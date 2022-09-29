`timescale 1ns / 1ps

module counter_delayed_trigger #
(
  parameter integer TRIGGER_COUNTER_WIDTH = 32,
	parameter integer TRIGGER_PRESAMPLES_WIDTH = 32
)
(
  input clk,
	input aresetn,
	input enable,
	input trigger_arm, // Arm the trigger
	input trigger_reset, // Unset the trigger after having triggered. Needs re-arming then.
  input counter_reset, // Reset the counter to zero and save last counter state.
	input [TRIGGER_PRESAMPLES_WIDTH-1:0] trigger_presamples, // Number of samples the trigger should be fired prior to reaching the last counter value
  input [TRIGGER_COUNTER_WIDTH-1:0] reference_counter, // The reference that is used for determining when to start the trigger. Note: Splitted off to allow for e.g using an average value of the polled last counter values.
	output trigger, // The actual trigger
	output trigger_armed, // Arming status of the trigger
	output [TRIGGER_COUNTER_WIDTH-1:0] last_counter // The last full counter value
);

// Delayed trigger counter
reg [TRIGGER_COUNTER_WIDTH-1:0] delayed_trigger_counter = 0;
reg [TRIGGER_COUNTER_WIDTH-1:0] last_counter_out = 0;
reg counter_reset_first = 0;
reg trigger_out = 0;
reg trigger_armed_int = 0;
reg trigger_armed_int_pre = 0;

always @(posedge clk)
begin
	if (~aresetn && enable)
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
		if ((trigger_armed_int == 1) && (delayed_trigger_counter >= reference_counter-trigger_presamples-1))
		begin
			trigger_out <= 1;
		end
		else
		begin
			if (trigger_reset == 1)
			begin
				trigger_out <= 0;
				trigger_armed_int <= 0;
				trigger_armed_int_pre <= 0;
			end
			else
			begin
				// React to trigger arming internally in order to allow for short arm pulses
				if (trigger_arm == 1)
				begin
					trigger_armed_int_pre <= 1;
				end
				
				// Only do internal arming when we would not directly trigger due to already satisfying the condition
				if ((trigger_armed_int_pre == 1) && ~(delayed_trigger_counter >= reference_counter-trigger_presamples-1))
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
		trigger_armed_int <= 0;
		trigger_armed_int_pre <= 0;
		
		// If the counter trigger is not enabled, it should always be on due to and-ing the triggers
		if (enable == 1)
		begin
			trigger_out <= 0;
		end
		else
		begin
			trigger_out <= 1;
		end
	end
end

assign trigger = trigger_out;
assign trigger_armed = trigger_armed_int;
assign last_counter = last_counter_out;

endmodule
