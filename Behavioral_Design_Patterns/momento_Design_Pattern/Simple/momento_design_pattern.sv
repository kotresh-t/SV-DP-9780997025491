// Memento Design Pattern example in SystemVerilog
// - Originator: holds state and can save/restore state via Memento
// - Memento: immutable snapshot of Originator state
// - Caretaker: keeps saved Mementos

module test_memento;

class Memento;
	string state;

	function new(string s);
		state = s;
	endfunction

	function string getState();
		return state;
	endfunction
endclass

class Originator;
	string state;

	function new(string s = "");
		state = s;
	endfunction

	function void setState(string s);
		state = s;
	endfunction

	function string getState();
		return state;
	endfunction

	function Memento saveToMemento();
		Memento var_m ; 
    var_m = new(state); 
    return var_m;
	endfunction

	function void restoreFromMemento(Memento m);
		if (m != null) state = m.getState();
	endfunction
endclass

class Caretaker;
	Memento mementos[$];

	function void addMemento(Memento m);
		mementos.push_back(m);
	endfunction

	function Memento getMemento(int idx);
		if (idx >= 0 && idx < mementos.size())
			return mementos[idx];
		else
			return null;
	endfunction

	function int size();
		return mementos.size();
	endfunction
endclass

	initial begin
		Originator orig = new("State #1");
		Caretaker caretaker = new();

		$display("Initial state: %s", orig.getState());
		caretaker.addMemento(orig.saveToMemento());

		orig.setState("State #2");
		$display("Changed to: %s", orig.getState());
		caretaker.addMemento(orig.saveToMemento());

		orig.setState("State #3");
		$display("Changed to: %s", orig.getState());

		// Restore to previous saved states
		orig.restoreFromMemento(caretaker.getMemento(1));
		$display("Restored to index 1: %s", orig.getState());

		orig.restoreFromMemento(caretaker.getMemento(0));
		$display("Restored to index 0: %s", orig.getState());

		$finish;
	end
endmodule
