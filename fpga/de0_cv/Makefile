MAP=$(QUARTUS_HOME)/bin/quartus_map
FIT=$(QUARTUS_HOME)/bin/quartus_fit
ASM=$(QUARTUS_HOME)/bin/quartus_asm --write_settings_files=off
CPF=$(QUARTUS_HOME)/bin/quartus_cpf --convert

OUTDIR=output_files
DBDIR=db

PROJECT=minimig_de0_cv

.PHONY: all
all: map fit asm cpf

.PHONY: map
map:
	@echo Running mapper ...
	@$(MAP) $(PROJECT) >map.log 2>&1

.PHONY: fit
fit:
	@echo Running fitter ...
	@$(FIT) $(PROJECT) >fit.log 2>&1

.PHONY: asm
asm:
	@echo Running assembler ...
	@$(ASM) $(PROJECT) >asm.log 2>&1

.PHONY: cpf
cpf:
	@echo Running converter ...
	@$(CPF) $(PROJECT).cof >cpf.log 2>&1

.PHONY: clean
clean:
	@echo clean
	@rm -rf $(OUTDIR)
	@rm -rf $(DBDIR)
	@rm -rf ./incremental_db/
