extends HsmState

func enter(_context: HsmContext) -> void:
    print("ENTER: ", name)


func exit(_context: HsmContext) -> void:
    print("EXIT: ", name)