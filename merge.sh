#bin/bash

echo "copy file from gcs for merging"
sudo mkdir /root/merging
sudo gsutil cp -r gs://${bucket_name}/userlisting/$date/*.csv /root/merging/

for file in /root/merging/*.csv; do
  cat "$file" >> "gcp_uar_list.csv"
#  rm "$f"
done
echo "pushing merged file to gcs"
gsutil cp -r /root/merging/*.csv gs://${bucket_name}/userlisting/
rm -rf /root/merging
