## Filing Bugs

If you're experiencing behavior that appears to be a bug in any of the Helm charts, you're welcome to [file an issue](https://github.com/rstudio/helm/issues/new). 

## Enhancements

You're also welcome to submit ideas for enhancements to our Helm charts. When doing so, please [search the issue list](https://github.com/rstudio/helm/issues) to see if the enhancement has already been filed. If it has, vote for it (add a reaction to it) and optionally add a comment with your perspective on the idea. 

## Contributing Code

We welcome contributions to our Helm charts! Before submitting your contribution, we ask that you ensure the change is helpful in a generic sense and is not tied to any specific organizational use-cases that would not be valuable to other organizations.

To submit a contribution:

1. [Fork](https://github.com/rstudio/helm/fork) the repository and make your changes.

2. Submit a [pull request](https://help.github.com/articles/using-pull-requests).

3. Sign the Contributor License Agreement via GitHub. A comment will be added to your pull request indicating if you need to sign the agreement and the link to do so.

We'll try to be as responsive as possible in reviewing and accepting pull requests. We highly appreciate your contributions!

## Assumptions / Common Dev Workflows

- Changes to the `rstudio-library` chart will update all downstream charts at
  the same time (via the `file://` syntax in `Chart.yaml`)
- CI only runs on local branches (i.e. not from forks). This can make
  evaluating code from contributors tricky. By creating a duplicate branch
  locally, we can "trick" CI into running on the same commits
- CI requires that the chart version get bumped for any change in the directory
  (including README)
- READMEs are generated in CI by [Go templating](./charts/_templates.gotmpl)
  and `helm-docs`
- If `index.yaml` gets out of date on the repository, see
  [`./scripts/`](./scripts) for a workflow to fix

## Code of Conduct

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This Code of Conduct is adapted from the Contributor Covenant, version 1.0.0, available at <https://www.contributor-covenant.org/version/1/0/0/code-of-conduct.html>.
