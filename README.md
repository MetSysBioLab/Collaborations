# Collaborations

Welcome to the collaborations workspace for the **Metabolic Systems Biology Laboratory (Q-Lab)** at the University of Florida.

This repository is a working space for collaborative computational projects, reproducible analyses, shared code, and tools developed to support research in metabolism, diabetes, pancreatic islet biology, mitochondrial biology, lysosome biology, and systems biology.

> **Status:** Active development. Some folders, scripts, and analyses may be incomplete, exploratory, or subject to change.

---

## Purpose

This repository is intended to make collaborative work easier to find, reproduce, review, and extend. It may include:

- Analysis pipelines for collaborative datasets
- Scripts for data cleaning, quality control, visualization, and statistical analysis
- Code for single-cell RNA-seq, bulk RNA-seq, spatial omics, imaging, and metabolic phenotyping datasets
- Machine-learning and systems-biology workflows
- Reusable utilities, templates, and documentation
- Work-in-progress analyses shared with collaborators for feedback and development

Unless otherwise stated in an individual project folder, all code and results should be considered **preliminary research material**. They should not be used for publication, redistribution, or clinical decision-making without approval from the relevant project leads.

---

## Repository Structure

```text
.
├── projects/                 # Individual collaboration-specific projects
│   ├── project-name/
│   │   ├── README.md         # Project goals, contacts, and instructions
│   │   ├── code/             # Analysis scripts and notebooks
│   │   ├── data/             # Data-access instructions; do not store restricted data here
│   │   ├── results/          # Derived results, figures, and summary outputs
│   │   └── docs/             # Methods, meeting notes, and supporting documentation
│
├── work-in-progress/         # Exploratory analyses and code under active development
├── shared-tools/             # Reusable functions, templates, and utilities
├── examples/                 # Example workflows and demonstration notebooks
├── docs/                     # General documentation and collaboration guidance
└── environment/              # Environment files and reproducibility specifications
```

---

## Current Work

| Folder / Area | Description | Status |
|---|---|---|
| `work-in-progress/` | Exploratory code, new methods, and analyses under active development | Ongoing |
| `shared-tools/` | Reusable scripts and utilities for common computational workflows | Ongoing |
| `projects/` | Collaboration-specific analysis folders | Varies by project |

Each project folder should contain a project-specific `README.md` with the research question, project contacts, dataset status, analysis plan, expected deliverables, and any restrictions on sharing or interpretation.

---

## Areas of Collaboration

The Metabolic Systems Biology Laboratory can contribute to collaborative projects involving:

- Experimental design and quantitative analysis for metabolic and diabetes research
- Pancreatic islet and β-cell biology
- Mitochondrial quality control and lysosomal biology
- Single-cell and spatial transcriptomics
- Bulk RNA-seq and transcriptomic analysis
- Multi-omics integration and systems-biology modeling
- Quantitative microscopy and image-analysis workflows
- Statistical modeling and data visualization
- Machine learning for biological and biomedical datasets
- Reproducible computational pipelines and code review
- Research data organization and analysis planning

If you are interested in collaborating, please provide a brief summary of the biological question, available data, desired analysis or deliverable, anticipated timeline, and relevant funding or publication plans.

---

## For Collaborators

Before beginning work in a project folder:

1. Read the relevant project `README.md`.
2. Confirm the scientific question, data-access requirements, and expected deliverables.
3. Create a separate Git branch for substantial changes.
4. Document key assumptions, parameters, software versions, and analysis decisions.
5. Use pull requests for substantial code additions or changes whenever possible.
6. Discuss interpretation of preliminary results with the project leads before external sharing.

---

## Starting a New Project

New collaboration folders should include:

- A concise project title and research question
- Names and contact information for project leads
- A description of the dataset and metadata available
- Data-access instructions and applicable restrictions
- Planned analyses and anticipated deliverables
- Expected timeline and milestones
- Authorship, acknowledgement, and publication expectations
- Institutional approvals, data-use agreements, or regulatory requirements, when applicable

A useful initial folder structure is:

```text
projects/
└── project-name/
    ├── README.md
    ├── code/
    ├── data/
    ├── results/
    └── docs/
```

---

## Data Security and Confidentiality

Do **not** upload any of the following to a public GitHub repository:

- Protected health information (PHI)
- Identifiable human-subject data
- Controlled-access or restricted datasets
- Credentials, passwords, API keys, or access tokens
- Confidential unpublished data without authorization
- Large raw data files unless expressly approved and managed through an appropriate storage system

For restricted datasets:

- Store data only in approved University of Florida or collaborator-approved secure locations.
- Use this repository for code, documentation, environment files, and data-access instructions rather than restricted raw data.
- Add data folders and credentials to `.gitignore`.
- Provide authorized users with clear instructions for obtaining or securely accessing the data.

Example `.gitignore` entries:

```gitignore
# Raw and restricted data
data/raw/
data/private/
*.csv
*.tsv
*.fastq
*.fastq.gz
*.bam
*.h5ad

# Credentials and secrets
.env
*.key
*.pem
credentials.json
```

---

## Reproducibility

Whenever possible, each project should include:

- A project-level `README.md`
- Clear input-data requirements and expected file structure
- Software, package, and tool versions
- A Conda environment file, `requirements.txt`, or equivalent
- Analysis parameters and run instructions
- Documentation of expected outputs
- A record of major analysis decisions

Example Conda setup:

```bash
conda env create -f environment/environment.yml
conda activate metabolic-systems-biology
```

---

## Authorship and Data Sharing

Collaborative analyses may involve meaningful intellectual, technical, and scientific contributions. Please discuss authorship, acknowledgements, data ownership, and publication plans early in the project and revisit these expectations as the project develops.

Do not distribute code, preliminary results, figures, data, or analyses outside the approved collaboration team without permission from the relevant project leads.

---

## Contact

**M. M. Fahd Qadir, DVM, MS, PhD**  
Assistant Professor and Director, Metabolic Systems Biology Laboratory  
Department of Pathology, Immunology and Laboratory Medicine  
University of Florida Diabetes Institute  
University of Florida College of Medicine  
Gainesville, Florida  

For collaboration inquiries: [m.qadir@ufl.edu](mailto:m.qadir@ufl.edu)

---

## License

Unless a project-specific license states otherwise, the code and materials in this repository are shared for approved academic research collaboration and internal use only. Reuse, redistribution, or commercial use requires prior written permission from the repository maintainers and, where applicable, collaborating investigators.
