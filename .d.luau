declare _G: {
	DALBIT_runtime_type_checking: boolean,
	DALBIT_hash_iterator: boolean,
	DALBIT_allow_debug_library_usage: boolean,
	DALBIT_emulate_frozen_table: boolean,
	DALBIT_emulate_newproxy: boolean,
	DALBIT_test: boolean,
	DALBIT_emulate_type_error: boolean,
	DALBIT_luau_hash_table: boolean,
	DALBIT_emulate_next: boolean,
	DALBIT_buffer_out_of_bounds: boolean,
}

declare load: <A...>(chunk: string | () -> string, chunkname: string?, mode: ("bt" | "b" | "t")?, env: { [string]: any }?) -> (((A...) -> any)?, string?)
