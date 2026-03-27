# Network Report

## Firewalls
| Name         | IP Address                |
|--------------|---------------------------|
| fw-1        | 192.168.1.1               |

## Load Balancers
| Name                | IP Address                                                                                     |
|---------------------|------------------------------------------------------------------------------------------------|
| stateless-fw-lb-1  | eth0 100.0.0.7/24, eth1 100.0.0.3/24, eth2 100.0.0.5/25                                   |
| stateless-fw-lb-2  | eth0 100.0.0.8/24, eth1 100.0.0.4/24, eth2 100.0.0.6/24                                   |

## Routers
| Name        | IP Address              |
|-------------|-------------------------|
| router-1   | 10.0.0.1                |

## Other Devices
| Name         | IP Address             |
|--------------|-------------------------|
| device-1    | 172.16.0.1              |

## Change Log
| Date       | Changed By  | Description                                                                            |
|------------|-------------|----------------------------------------------------------------------------------------|
| 2026-03-27 | lucaveiro   | Updated Firewalls, Load Balancers, Routers, and Other Devices tables; added new Load Balancers.