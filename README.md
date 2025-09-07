# How To Deploy Monitoring Tool For HPC Systems

## For Head Node

### Preparation
1. Make sure to update the system and install some simple tools
```
sudo apt update && sudo apt install -y curl wget git
```

2. Check for required packages
```
sudo apt list -installed | grep -E "(python3|pip|curl|wget|git)" | head -10
```

### Setup InfluxDB as the database layer
1. Move to the InfluxDb-VM directory
```
cd InfluxDb-VM
```

2. Install dos2unix package for converting files
```
sudo apt install -y dos2unix
```

3. Convert influxdb.sh file
```
dos2unix influxdb.sh
```

4. Grant executive right and install InfluxDB
```
chmod +x influxdb.sh && ./influxdb.sh
```

5. After successfully start InfluxDB, go to http://localhost:8086 and create and account, then store the returned token in a file. When creating the account, the following information is required:
* Username
* Password
* Organization
* Bucket
Please remember these information for latter use

6. Get the IP of the system and remember for latter use
```
hostname -I | awk '{print $1}'
```

7. Create a configuration file
```
sudo tee /root/.env > /dev/null <<EOF
INFLUX_URL=http://localhost:8086
INFLUX_TOKEN=<replace by your token>
INFLUX_ORG=<replace by your organization>
INFLUX_BUCKET_VM=<replace by your bucket>
INFLUX_HOSTNAME=<replace by your IP address>
EOF
```

8. Check for InfluxDB service's status
```
sudo systemctl status influxdb -no-pager
```

### Setup Grafana
1. Move to the Grafana-VM directory
```
cd ./Grafana-VM
```

2. Convert grafana.sh file
```
dos2unix grafana.sh
```

3. Check for the system's architecture
```
uname -m
```
Note for the ARM architecture:
* Download Grafana:
```
wget https://dl.grafana.com/oss/release/grafana_11.2.0_arm64.deb
```
* Install Grafana:
```
sudo dpkg -i grafana_11.2.0_arm64.deb
```

4. Grant executive right and install Grafana
```
chmod +x grafana.sh && ./grafana.sh
```

5. Check for Grafana service's status
```
sudo systemctl status grafana-server -no-pager
```

### Setup Telegraf (For both Head node and Sub-node)
1. Download Telegraf (Remember to check for the system's architecture to download the right version)
```
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.27.1-1_amd64.deb
```

2. Install Telegraf
```
sudo dpkg -i telegraf_1.27.1-1_amd64.deb
```

3. Create configuration file
```
sudo nano /etc/telegraf/telegraf.conf
```

4. Insert the following into the configuration file
```
# Agent Configuration
[agent]
  interval = "5s"
  flush_interval = "5s"
  hostname = "<node-name>"

# Output Plugin for InfluxDB
[[outputs.influxdb_v2]]
  urls = ["<IP address of the head node>"]
  token = "<InfluxDB's token>"
  organization = "<InfluxDB's organization>"
  bucket = "<InfluxDB's bucket>"

# Read metrics about cpu usage
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = true

# Read metrics about disk IO by device
[[inputs.diskio]]

# Read metrics about memory usage
[[inputs.mem]]

[[inputs.processes]]

[[inputs.system]]
```

5. Start Telegraf
```
sudo systemctl start telegraf
```
