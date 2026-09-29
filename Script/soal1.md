1. Configure <br>
   IP router : 127.0.0.1
   Router :
   ```bash
    auto eth0
    iface eth0 inet dhcp

    auto eth1
    iface eth1 inet static
        address 10.92.1.1
        netmask 255.255.255.0

    auto eth2
    iface eth2 inet static
        address 10.92.2.1
        netmask 255.255.255.0

    auto eth3
    iface eth3 inet static
        address 10.92.3.1
        netmask 255.255.255.0

    auto eth4
    iface eth4 inet static
        address 10.92.4.1
        netmask 255.255.255.0

    auto eth5
    iface eth5 inet static
        address 10.92.5.1
        netmask 255.255.255.0
   ```

    Prab :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.2
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    tedd :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.3
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    obladi :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.4
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    desmond :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.5
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    oblada :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.6
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    molly :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.1.7
        netmask 255.255.255.0
        gateway 10.92.1.1
    ```

    abbey :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.2.2
        netmask 255.255.255.0
        gateway 10.92.2.1
    ```

    penny :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.3.2
        netmask 255.255.255.0
        gateway 10.92.3.1
    ```

    alpha :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.4.2
        netmask 255.255.255.0
        gateway 10.92.4.1
    ```

    beta :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.4.3
        netmask 255.255.255.0
        gateway 10.92.4.1
    ```    

    gamma :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.4.4
        netmask 255.255.255.0
        gateway 10.92.4.1
    ``` 

    delta :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.5.2
        netmask 255.255.255.0
        gateway 10.92.5.1
    ``` 

    epsilon :
    ```bash
    auto eth0
    iface eth0 inet static
        address 10.92.5.3
        netmask 255.255.255.0
        gateway 10.92.5.1
    ``` 