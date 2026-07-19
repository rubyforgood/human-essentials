# Code Standards

Human Essentials is largely a volunteer-driven project. Because contributors can come from all skill levels, it's important to ensure there is a baseline of code quality that is followed for all contributions.

## Code Style

Code style should be enforced by Rubocop. There are a few things Rubocop doesn't enforce, such as:

* Prefer `if` over `unless` for conditionals, especially if there are multiple clauses.
* For service classes, prefer class-level methods over requiring instantiation. It's easier to reason about and test.
* Don't use bare hashes - prefer `Data` (immutable) or `Struct` (mutable) classes instead. This gives us better type safety.
* Don't overuse instance variables in controllers. It's better to define a Struct to represent the data your view needs.

## Architecture

* Prefer service classes over Rails model callbacks. In general, models should only be concerned with speaking to the database - all more complex logic should be in service classes.
* Validations should only be concerned with the table represented by the model. Validating external data is tricky and can make workflows break in weird situations. If you need to validate external data, do it in a service class and change the workflow so all creation/updates happen through that service class.
* Use the database as much as possible - it's faster and cleaner than doing things in-memory. (Within reason - if performance is not important, and the SQL query would be big and hairy, you can definitely reach for Ruby.)
* In general, prefer being explicit over dynamic. Rails itself uses lots of dynamic programming, but application code should stay away from it if at all possible. It means a bit more typing, but is almost always worth it. That means staying away from e.g. `define_method` or `method_missing`.
* Don't introduce new dependencies such as gems or JavaScript modules unless you're very sure it's necessary. Often dependencies can save a bit of typing, but they introduce complexity and require keeping them up to date.
* Don't be afraid to reach for bare SQL, especially for complex queries like reports. ActiveRecord has gotten a lot better over the years, but sometimes you need more tools in your toolbox.
* We don't have many examples yet, but please use [explicit local variables](https://github.com/rails/rails/pull/45602) in your views.

## Testing

* ***Always, always*** prefer request tests over system tests. System tests are slow and flaky. Requests tests are fast and much more easily reproducible.
* Do not use controller tests - they are deprecated. Replace them with request tests.
* Try not to introduce shared examples. They can be unwieldy to use and hard to understand.
* Use `let` for setup that would be reused across multiple tests. Use `let!` if the data needs to be created before the test runs. If the data needs to be created but is *not* referenced in the test, use `before(:each)` instead.
* Use real database data as much as possible. Stubbing out methods like `find`, `where`, or even the inventory aggregate can make tests faster, but they then don't test the real functionality. Use `create_inventory` for those tests, and use FactoryBot for creating real data.
* Do not rely on fields that are filled in by factories in your tests. Any time you want to test a specific value, fill it in explicitly. We've run into issues in the past where factory data messed up the tests in unexpected ways (e.g. it introduced an apostrophe). Factory data is there to create the data that's *necessary for internal consistency* that the test doesn't care about - not for actual test data.

