# BWASPR Installation and Setup

## Installation as a singularity container [![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3301)

All the BWASPR dependencies are encapsulated in a
[Singularity](https://www.sylabs.io/docs/) container available from our group
[Singularity Hub](http://BrendelGroup.org/SingularityHub/).

Assuming _git_ and  _singularity_ are installed on your system, you can get the
BWASPR code from GitHub and the container from our
[Singularity Hub](http://BrendelGroup.org/SingularityHub/) as follows:

```bash
git clone https://github.com/BrendelGroup/BWASPR.git
cd BWASPR/demo
singularity pull http://BrendelGroup.org/bwaspr.sif
singularity exec -e -B `pwd` bwaspr.sif ./xdoit sample OUT-sample
```

Here the last command (_singularity exec_) will execute the _Rscript.BWASPR_
workflow described in the [demo](./demo) directory, using all the required
R packages already loaded in the singularity container.

For a gentle introduction to singularity, see our group
[handbook article](https://github.com/BrendelGroup/bghandbook/blob/master/doc/06.2-Howto-Singularity-run.md).


## Optional: System-wide Installation

BWASPR use via the singularity container is highly recommended, with no known
drawbacks.
However, if desired, you can of course install all the required R packages
individually on your computer system.
The singularity [recipe file](./Singularity) in this repository should serve as
a guide to perform such an installation.
The `bwaspr.sif` container was built on the 
[current long-term supported Ubuntu 20.04 distribution](https://www.ubuntu.com/download/desktop)
and thus the instructions apply to that particular Linux version.
For different Linux distributions, you will have to install the equivalent
packages using your distribution's package manager.


## Finally

proceed to the [demo/README](./demo/README.md) document, and we'll tell you how
to execute sample workflows (or, equally easy, your very own data analyses).
