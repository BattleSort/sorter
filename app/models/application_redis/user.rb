class User < ApplicationRedis
    attr_accessor :problems
    def add_problem(problem)
        self.problems.push(problem)
        save
    end
end
