

# Consistent Code Linting for Multiple Projects  
  
This project is meant to solve the problem of maitaining multiple linting configuration files in multiple projects by factoring out common configuration into the cloud and providing a universal script to run various linters.

**Features**

 - Support for multiple languages and frameworks
 - Default linter configurations can be overridden locally
 - Provides a central location for making changes to linter configuration.
 - A single script runs all linters in sequence and can be automated using CI pipelines
  
## Installation

1. Create a file called `lint` with the following contents at the root of your project or in the `bin` directory inside your project (although any other location inside your project would work as well).

    ```bash
    #!/usr/bin/env bash
    curl [REPO_URL]/lint.sh | bash -s [args]
    ```

    *  `REPO_URL` is the fully qualified link to the `lint.sh` file inside this repository (or your repository in case of a fork). To find this link, simply view the file in the **raw** format.
    * `args` is a space-separated list of linters

2. Make the file executable with `chmod +x lint`

Here's what your `lint` file might look like:

```bash
#!/usr/bin/env bash
curl https://code-linting/master/lint.sh | bash -s ruby rails js jsx sass
```

## Usage

**Always navigate to the root of your project before running the script.**

Suppose your script is located in the `bin` directory of your project. You would run it with:
  
`bin/lint`
  
## Supported Linters  
  
The list of supported linters can be found at the top of the `lint.sh` file.


## Auto-Correction  
  
Where available, the script will try to auto-correct errors. **Use with caution.**  

## Contributing 
  
1. Fork it  
2. Create your feature branch (`git checkout -b my-new-feature`)  
3. Commit your changes (`git commit -am 'Add some feature'`)  
4. Push to the branch (`git push origin my-new-feature`)  
5. Create new Pull Request  
  
  
## License  
  
The project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).