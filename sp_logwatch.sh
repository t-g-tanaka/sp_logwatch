#!/bin/bash

# sp_logwatch : �w���path�ɑ��݂���(���O)�t�@�C������
#       ����̕����񂪏o���������ǂ��������m���A�o�͂���B
#       Nagios plugin�Ƃ��Ă̓����z��
#
# Todo:	����N�����A�����ݒ蓮�샂�[�h
#	���ꎩ�g�̏ڍ׃��Orotate: 1w�ۑ�(�o�͐�mmdd, �Â��̏���)
#	���݂̎��z�X�g���̑Ώ�path�Apattern�o�̓��[�h�ǉ�
#	�Ď��Ώۃ��X�g�̒u����

# �Ď��Ώۃ��X�g�Fwget�Ŏ擾���邱�Ƃ�z��
OBJLIST="sp_logwatch.dat"
# OBJLISTPATH="http://*.*.*/*/${OBJLIST}"

tmp=$(readlink -f $0)
HOMEDIR=$(dirname $tmp)
SPDBDIR="${HOMEDIR}/db"
SPWORKDIR="${HOMEDIR}/work"
SPWORKOBJ="objfiles.dat"
CHK_CONT="cont_diff.dat"
MYHOSTNAME=$(hostname -s)
TMP_OUT="results.dat"
MSG_SUM=""

cd $SPWORKDIR
rm -f $TMP_OUT
# wget $OBJLISTPATH
#echo ${MYHOSTNAME}:${HOMEDIR}

### ���X�g����Ώۃf�[�^�ǂݍ���
# while read ...
# do
### �z�X�g���F$ohost, �p�X�F$opath
ohost="aatmfdev0001"
opath="/var/log/mf2/mongo2solr_wrapper/*/*/*.log"
opattern="failed to update data"

if [ $ohost = $MYHOSTNAME ]; then
   ls $opath 1> $SPWORKOBJ 2> /dev/null
   if [ $? -eq 0 ]; then
      while read ofile
      do
         if [ -e ${SPDBDIR}${ofile} ]; then
            read checked < ${SPDBDIR}${ofile}
            read md5prev < ${SPDBDIR}${ofile}.md5
            md5curr=$(head -n $checked ${ofile} | md5sum)
            nlines=$(wc -l < ${ofile})
            if [ "$md5prev" = "$md5curr" ]; then
               olines=$((${checked} + 1))
               tail -n +${olines} ${ofile} > $CHK_CONT
            else
echo "# target rotated : ${ofile}"
               cp ${ofile} $CHK_CONT # rotated
            fi
         else
            mkdir -p $(dirname ${SPDBDIR}${ofile})
            nlines=$(wc -l < ${ofile})
            cp ${ofile} $CHK_CONT
echo "# New target : ${ofile}"
         fi
         echo $nlines > ${SPDBDIR}${ofile}
         head -n $nlines ${ofile} | md5sum > ${SPDBDIR}${ofile}.md5
         result=$(cat $CHK_CONT | grep "${opattern}")
         if [ -n "$result" ]; then
            MSG_SUM="${MSG_SUM} ${ofile}"
            echo ${ofile}: >> $TMP_OUT
            echo '>' ${result} >> $TMP_OUT
         fi
      done < $SPWORKOBJ
   fi
fi
# done

rm -f $CHK_CONT $SPWORKOBJ
if [ -e $TMP_OUT ]; then
#  cat $TMP_OUT
   echo "WARNING: defined log has been recorded in${MSG_SUM}"
   rm -f $TMP_OUT
   exit 1 # WARNING
else
   echo OK
   exit 0 # OK
fi
