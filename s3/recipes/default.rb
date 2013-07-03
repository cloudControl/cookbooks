## Source accepts the protocol s3:// with the host as the bucket
## access_key_id and secret_access_key are just that
#s3_file "/var/bulk/the_file.tar.gz" do
#  source "s3://your.bucket/the_file.tar.gz"
#  access_key_id your_key
#  secret_access_key your_secret
#  owner "root"
#  group "root"
#  mode 0644
#end
