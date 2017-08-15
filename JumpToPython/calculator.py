class Calculator:
    def __init__(self, ls):
        self.result = 0
        self.list = ls        
        
    def sum(self):
        self.result = sum(self.list)
        return self.result
    
    def avg(self):
        if(self.result==0):self.sum()
        self.result = self.result/len(self.list)       
        return self.result