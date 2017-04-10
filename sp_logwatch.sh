#!/bin/bash

# sp_logwatch : 指定のpathに存在する(ログ)ファイル内に
#       特定の文字列が出現したかどうかを検知し、出力する。
#       Nagios pluginとしての動作を想定
#
# Todo:	初回起動時、初期設定動作モード
#	これ自身の詳細ログrotate: 1w保存(出力先mmdd, 古いの消去)
#	現在の自ホスト内の対象path、pattern出力モード追加
#	監視対象リストの置き場

# 監視対象リスト：wgetで取得することを想定
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

### リストから対象データ読み込み
# while read ...
# do
### ホスト名：$ohost, パス：$opath
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
