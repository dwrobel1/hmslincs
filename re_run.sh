#!/bin/bash
# note: if using virtualenv, set that up before running this script

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR: ${1} : ${2}"
    exit ${1}
  fi
}


dropdb -U django django 
check_errs $? "dropdb fails"

createdb -Udjango -T django_init django
check_errs $? "createdb fails"

django/manage.py syncdb
check_errs $? "syncdb fails"

echo 'import cell table ...'
python src/populate_cell.py sampledata/LINCS_Cells_20120727.xls 'HMS-LINCS cell line metadata'
check_errs $? "populate cell fails"

echo 'import small molecule...'
python src/populate_smallmolecule.py sampledata/HMS_LINCS-1.sdf
check_errs $? "import sdf fails"

python src/import_libraries.py -f sampledata/libraries.xls
check_errs $? "import library fails"

echo 'import kinases...'
python src/import_protein.py -f sampledata/HMS-LINCS_KinaseReagents_MetaData_20120906_DRAFT.xls
check_errs $? 'import kinases fails'

echo 'import screen results...'
python src/import_dataset.py -f sampledata/moerke_2color_IA-LM.xls 
check_errs $? "import dataset fails"
python src/import_dataset.py -f sampledata/tang_MitoApop2_5637.xls
check_errs $? "import dataset result fails"

echo 'import studies'
python ./src/import_dataset.py -f sampledata/Study300002_HMSL10008_sorafenib_ambit.xls
check_errs $? "import study dataset fails"

python src/create_indexes.py | psql -Udjango django  -v ON_ERROR_STOP=1
check_errs $? "create indexes fails"
