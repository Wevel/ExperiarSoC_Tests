import dataclasses
import os
import typing


@dataclasses.dataclass(frozen=True, eq=True)
class Instruction:
	pass

@dataclasses.dataclass(frozen=True, eq=True)
class Input:
	name: str
	width: int = 1

@dataclasses.dataclass(frozen=True, eq=True)
class Output:
	name: str
	width: int = 1

@dataclasses.dataclass(frozen=True, eq=True)
class Wire:
	name: str
	width: int = 1

@dataclasses.dataclass(frozen=True, eq=True)
class Statement:
	text: str

@dataclasses.dataclass(frozen=True)
class VerilogFileBuilder:
	module_name: str
	inputs: list[Input] = dataclasses.field(default_factory=list)
	outputs: list[Output] = dataclasses.field(default_factory=list)
	wires: list[Wire] = dataclasses.field(default_factory=list)
	statements: list[Statement] = dataclasses.field(default_factory=list)

	def add_input(self, name, width=1):
		self.inputs.append(Input(name, width))

	def add_output(self, name, width=1):
		self.outputs.append(Output(name, width))

	def add_wire(self, name, width=1):
		self.wires.append(Wire(name, width))

	def add_statement(self, statement):
		self.statements.append(Statement(statement))

	def build(self):
		verilog = f"module {self.module_name} (\n"
		verilog += ",\n".join([f"	input [{input.width-1}:0] {input.name}" for input in self.inputs])
		verilog += ",\n"
		verilog += ",\n".join([f"	output [{output.width-1}:0] {output.name}" for output in self.outputs])
		verilog += "\n);\n\n"
		verilog += "\n".join([f"	wire [{wire.width-1}:0] {wire.name};" for wire in self.wires])
		verilog += "\n\n"
		verilog += "\n".join([f"	{statement.text};" for statement in self.statements])
		verilog += "\n\nendmodule\n"
		return verilog
	
def add_lines_to_template(template_file: str, start_marker: str, end_marker: str, lines_to_add: list[str], output_file: str) -> None:
	if not os.path.isfile(template_file):
		raise ValueError("Template file does not exist")
	
	with open(template_file, "r") as f:
		template_lines = f.readlines()

	start_index = None
	end_index = None
	for i, line in enumerate(template_lines):
		if start_marker in line:
			start_index = i
		elif end_marker in line:
			end_index = i
			break

	if start_index is None or end_index is None:
		raise ValueError("Start or end marker not found in template file")

	new_lines = template_lines[:start_index+1] + lines_to_add + template_lines[end_index:]

	with open(output_file, "w") as f:
		f.writelines(new_lines)

builder = VerilogFileBuilder("my_module")
builder.add_input("a", 8)
builder.add_input("b", 8)
builder.add_output("c", 8)
builder.add_wire("d", 8)
builder.add_statement("assign d = a + b;")
builder.add_statement("assign c = d;")
verilog = builder.build()
print(verilog)