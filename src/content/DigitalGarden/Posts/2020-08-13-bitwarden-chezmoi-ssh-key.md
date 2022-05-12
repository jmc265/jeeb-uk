---
title:  "Using BitWarden and Chezmoi to manage SSH keys"
permalink: bitwarden-chezmoi-ssh-keys/
layout: post
tags: 
  - posts
  - programming
  - chezmoi
  - bitwarden
  - unix
  - ssh
---

I have recently started using [Chezmoi](https://www.chezmoi.io/) to manage my dotfiles (and various other pieces software config) across multiple machines. The distribution is done via a git repo and therefore we should not check in secrets such as the private part of the SSH key. Using [Bitwarden](https://bitwarden.com/), we can store the key in a Secure Note and retrieve on the other machines.

## Setup

The rest of this post assumes you already have [Chezmoi](https://www.chezmoi.io/) installed and set up:

```bash
curl -sfL https://git.io/chezmoi | sh
chezmoi init
```

You will also need a pre-existing SSH key:

```bash
ssh_keygen -o
```

## Store the key

The public key part of the SSH key can be stored in Chezmoi in plain text:

```bash
chezmoi add .ssh/id_rsa.pub
```

To store the private part we are going to need to install the [`bitwarden-cli`](https://github.com/bitwarden/cli) and then login and unlock it:

```bash
bw login <EMAIL-ADDRESS>
bw unlock
export BW_SESSION="<SESSION-ID>"
```

Now, we get to the magic sauce. This line will store your SSH key (stored at `~/.ssh/id_rsa`) in a secure note in Bitwarden:

```bash
echo "{\"organizationId\":null,\"folderId\":null,\"type\":2,\"name\":\"sshkey\",\"notes\":\"$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\\\n/g' ~/.ssh/id_rsa)\",\"favorite\":false,\"fields\":[],\"login\":null,\"secureNote\":{\"type\":0},\"card\":null,\"identity\":null}" | bw encode | bw create item
```

And finally, we need to tell chezmoi where to get the key from. Create a file in your chezmoi repo at this location: `private_dot_ssh/private_id_rsa.tmpl` and add this as the contents:

{% raw %}
```
{{ (bitwarden "item" "sshkey").notes }}
```
{% endraw %}

(For OSX, this file needs a new line character at the end. For Linux, I believe it mustn't, so you might need to end the file with `-}}` instead)

Make sure all the files are committed and pushed to the origin.

## Retrieve the key

On another machine where you want to retrieve the same key, make sure `bitwarden-cli` and Chezmoi are installed and first do the same login and unlock steps for Bitwarden as above. Then simplpy do:

```bash
chezmoi init --apply <GIT-REPO>
```

And that's it. Check your private key has made it safely to your machine by doing `cat ~/.ssh/id_rsa`.

You can see the full example of my chezmoi config [here](https://github.com/jmc265/dotfiles).