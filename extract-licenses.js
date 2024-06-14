const fs = require("fs")
const path = require("path")
const execSync = require("child_process").execSync

// Run license-checker and get the JSON output
execSync("license-checker --json > licenses.json")

const licenses = require("./licenses.json")

for (const [packageName, packageInfo] of Object.entries(licenses)) {
    const licenseFilePath = packageInfo.licenseFile
    if (licenseFilePath && fs.existsSync(licenseFilePath)) {
        const targetDir = path.join(
            __dirname,
            "third_party_licenses",
            packageName.replace("/", "-"),
        )
        fs.mkdirSync(targetDir, { recursive: true })
        fs.copyFileSync(licenseFilePath, path.join(targetDir, "LICENSE"))
        console.log(`Copied LICENSE for ${packageName} to ${targetDir}`)
    } else {
        console.warn(`License file for ${packageName} not found`)
    }
}
