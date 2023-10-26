import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as random from "@pulumi/random";
import * as fs from "fs";

const main = async () => {
	const DNS_ZONE_NAME: string = process.env.DNS_ZONE_NAME!;
	const secretId = "projects/578019966278/secrets/doppler-cloud";

	// const teleportJoinToken = new random
	const dnsZone = await gcp.dns.getManagedZone({
		name: DNS_ZONE_NAME,
	});

	const network = new gcp.compute.Network("network", {
		description: "Network for rawkode.cloud",
		autoCreateSubnetworks: true,
	});

	new gcp.compute.Firewall("firewall", {
		name: "rawkode-cloud",
		network: network.name,
		allows: [
			{
				protocol: "tcp",
				ports: ["22", "443"],
			},
		],
		targetTags: ["allow-https-ingress"],
	});

	const fixedIp = new gcp.compute.Address("fixed-ip", {});

	const serviceAccount = new gcp.serviceaccount.Account("rawkode-cloud", {
		accountId: "rawkode-cloud",
		displayName: "rawkode.cloud",
	});

	const rawkodeCloudSharedSecret = new gcp.secretmanager.Secret(
		"rawkode-cloud",
		{
			secretId: "rawkode-cloud-shared",
			replication: {
				automatic: true,
			},
		},
	);

	const teleportJoinToken = new random.RandomString("teleport-join-token", {
		length: 32,
	});

	const rawkodeCloudSharedSecretVersion = new gcp.secretmanager.SecretVersion(
		"rawkode-cloud-shared",
		{
			secret: rawkodeCloudSharedSecret.name,
			enabled: true,
			secretData: pulumi
				.all([teleportJoinToken.result])
				.apply(([teleportJoinToken]) => {
					return JSON.stringify({
						TELEPORT_JOIN_TOKEN: teleportJoinToken,
					});
				}),
		},
	);

	new gcp.secretmanager.SecretIamBinding("doppler-integration", {
		role: "roles/secretmanager.secretAccessor",
		members: [pulumi.interpolate`serviceAccount:${serviceAccount.email}`],
		secretId,
	});

	new gcp.secretmanager.SecretIamBinding("rawkode-cloud", {
		role: "roles/secretmanager.secretAccessor",
		members: [pulumi.interpolate`serviceAccount:${serviceAccount.email}`],
		secretId: rawkodeCloudSharedSecret.name,
	});

	new gcp.compute.Instance("instance", {
		name: "rawkode-cloud",
		machineType: "e2-standard-4",
		zone: "europe-west2-a",
		tags: ["allow-https-ingress"],
		bootDisk: {
			initializeParams: {
				image: "ubuntu-os-cloud/ubuntu-2204-lts",
			},
		},
		networkInterfaces: [
			{
				network: network.selfLink,
				accessConfigs: [
					{
						natIp: fixedIp.address,
					},
				],
			},
		],
		metadata: {
			DNS_NAME: dnsZone.dnsName.slice(0, -1),
		},
		serviceAccount: {
			email: serviceAccount.email,
			scopes: ["cloud-platform"],
		},
		metadataStartupScript: fs
			.readFileSync("../cloud-config/teleport.sh")
			.toString(),
		allowStoppingForUpdate: true,
	});

	const record = new gcp.dns.RecordSet(
		`${dnsZone.dnsName}-a`.toLowerCase(),
		{
			managedZone: dnsZone.name,
			ttl: 300,
			type: "A",
			rrdatas: [fixedIp.address],
			name: dnsZone.dnsName,
		},
		{
			deleteBeforeReplace: true,
		},
	);
};

main().then(() => console.log("Completed"));
